import type { FastifyInstance, FastifyReply } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAdmin } from '../auth';
import { serTeam, serEmployee, serNeed, serComment, serPost, parseImages } from '../serialize';
import { recalcTeamScore } from '../teamScore';
import { purgeNeedScopedRatings, recalcNeedScore } from '../needScore';
import { removeUploadedImages } from '../uploads';

const colorSchema = z.string().regex(/^#[0-9a-fA-F]{6}$/, '颜色格式应为 #RRGGBB');
const distSchema = z.array(z.number().int().min(0)).length(10);
const PALETTE: Array<[string, string]> = [
  ['#8E9BFF', '#5B6CFF'],
  ['#FFB36B', '#FF7A45'],
  ['#6BD9B5', '#2BC48A'],
  ['#FF9AA2', '#F23441'],
  ['#7FC8F8', '#12B5CB'],
  ['#C9A7FF', '#8E4DFF'],
];

const teamSchema = z.object({
  name: z.string().min(1, '请填写团队名称').max(20),
  category: z.enum(['c', '中']),
  short: z.string().min(1).max(2).optional(),
  iconKey: z.string().min(1),
  color1: colorSchema.optional(),
  color2: colorSchema.optional(),
  tags: z.array(z.string().max(12)).max(6).optional(),
  score: z.number().min(0).max(10).optional(),
  count: z.number().int().min(0).optional(),
  dist: distSchema.optional(),
  sort: z.number().int().optional(),
});

const employeeSchema = z.object({
  teamId: z.number().int().positive(),
  name: z.string().min(1, '请填写员工姓名').max(20),
  title: z.string().min(1, '请填写职位').max(20),
  iconKey: z.string().nullable().optional(),
  color1: colorSchema.optional(),
  color2: colorSchema.optional(),
  score: z.number().min(0).max(10).optional(),
  count: z.number().int().min(0).optional(),
  dist: distSchema.optional(),
  sort: z.number().int().optional(),
});

const needMemberSchema = z.object({
  employeeId: z.number().int().positive(),
  role: z.enum(['提议', '负责', '参与']),
});

const needSchema = z.object({
  title: z.string().min(1, '请填写需求标题').max(60),
  desc: z.string().min(1, '请填写需求描述').max(1000),
  category: z.string().min(1, '请填写分类').max(16),
  status: z.enum(['评审中', '进行中', '已完成']),
  teamId: z.number().int().positive().nullable().optional(),
  proposerName: z.string().max(20).nullable().optional(),
  tags: z.array(z.string().max(12)).max(6).optional(),
  score: z.number().min(0).max(10).optional(),
  count: z.number().int().min(0).optional(),
  dist: distSchema.optional(),
  sort: z.number().int().optional(),
  members: z.array(needMemberSchema).max(20).optional(),
});

async function checkIcon(key: string, kind: string, reply: FastifyReply) {
  const icon = await prisma.icon.findUnique({ where: { key } });
  if (!icon || icon.kind !== kind) {
    reply.code(400).send({ error: `图标 ${key} 不在 ${kind} 图标池中` });
    return false;
  }
  return true;
}

function pickPalette(seed: string): [string, string] {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  return PALETTE[h % PALETTE.length];
}

function serIcon(i: any) {
  return { id: i.id, key: i.key, kind: i.kind, name: i.name, svg: i.svg, sort: i.sort };
}

/* Rating / Comment 为多态关联，无外键，删除主体时需手动清理 */
async function purgeTargets(targets: Array<{ type: string; ids: number[] }>) {
  for (const t of targets) {
    if (!t.ids.length) continue;
    await prisma.rating.deleteMany({ where: { targetType: t.type, targetId: { in: t.ids } } });
    await prisma.comment.deleteMany({ where: { targetType: t.type, targetId: { in: t.ids } } });
    await prisma.notification.deleteMany({ where: { targetType: t.type, targetId: { in: t.ids } } });
  }
}

export async function adminRoutes(app: FastifyInstance) {
  app.addHook('preHandler', requireAdmin);

  app.get('/stats', async () => {
    const [teams, employees, needs, users, ratings, comments, posts] = await Promise.all([
      prisma.team.count(),
      prisma.employee.count(),
      prisma.need.count(),
      prisma.user.count(),
      prisma.rating.count(),
      prisma.comment.count(),
      prisma.post.count(),
    ]);
    return { teams, employees, needs, users, ratings, comments, posts };
  });

  /* ========== 团队 ========== */
  app.get('/teams', async () => {
    const teams = await prisma.team.findMany({
      include: { _count: { select: { employees: true } } },
      orderBy: [{ sort: 'asc' }, { id: 'asc' }],
    });
    return { teams: teams.map(t => ({ ...serTeam(t), employeeCount: t._count.employees })) };
  });

  app.post('/teams', async (req, reply) => {
    const parsed = teamSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    if (!(await checkIcon(d.iconKey, 'team', reply))) return;
    if (await prisma.team.findUnique({ where: { name: d.name } })) {
      return reply.code(409).send({ error: '团队名称已存在' });
    }
    const [c1, c2] = pickPalette(d.name);
    const team = await prisma.team.create({
      data: {
        name: d.name,
        category: d.category,
        short: d.short || d.name.slice(0, 1),
        iconKey: d.iconKey,
        color1: d.color1 || c1,
        color2: d.color2 || c2,
        tags: JSON.stringify(d.tags || []),
        score: d.score || 0,
        ratingCount: d.count || 0,
        dist: JSON.stringify(d.dist || Array(10).fill(0)),
        sort: d.sort ?? 0,
      },
    });
    return { team: serTeam(team) };
  });

  app.put('/teams/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = teamSchema.partial().safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    if (d.iconKey && !(await checkIcon(d.iconKey, 'team', reply))) return;

    const exists = await prisma.team.findUnique({ where: { id } });
    if (!exists) return reply.code(404).send({ error: '团队不存在' });
    if (d.name && d.name !== exists.name) {
      if (await prisma.team.findUnique({ where: { name: d.name } })) {
        return reply.code(409).send({ error: '团队名称已存在' });
      }
    }

    const data: any = {};
    if (d.name !== undefined) data.name = d.name;
    if (d.category !== undefined) data.category = d.category;
    if (d.short !== undefined) data.short = d.short;
    if (d.iconKey !== undefined) data.iconKey = d.iconKey;
    if (d.color1 !== undefined) data.color1 = d.color1;
    if (d.color2 !== undefined) data.color2 = d.color2;
    if (d.tags !== undefined) data.tags = JSON.stringify(d.tags);
    if (d.score !== undefined) data.score = d.score;
    if (d.count !== undefined) data.ratingCount = d.count;
    if (d.dist !== undefined) data.dist = JSON.stringify(d.dist);
    if (d.sort !== undefined) data.sort = d.sort;

    const team = await prisma.team.update({ where: { id }, data });
    return { team: serTeam(team) };
  });

  app.delete('/teams/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    if (!(await prisma.team.findUnique({ where: { id } }))) {
      return reply.code(404).send({ error: '团队不存在' });
    }
    const empIds = (await prisma.employee.findMany({ where: { teamId: id }, select: { id: true } })).map(e => e.id);
    if (empIds.length) {
      await prisma.needMember.deleteMany({ where: { employeeId: { in: empIds } } });
    }
    await purgeTargets([
      { type: 'team', ids: [id] },
      { type: 'employee', ids: empIds },
    ]);
    await prisma.team.delete({ where: { id } });
    return { ok: true };
  });

  /* ========== 员工 ========== */
  app.get('/employees', async () => {
    const employees = await prisma.employee.findMany({
      include: { team: true },
      orderBy: [{ teamId: 'asc' }, { sort: 'asc' }, { id: 'asc' }],
    });
    return {
      employees: employees.map(e => ({ ...serEmployee(e), teamName: e.team.name })),
    };
  });

  app.post('/employees', async (req, reply) => {
    const parsed = employeeSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    if (d.iconKey && !(await checkIcon(d.iconKey, 'employee', reply))) return;
    if (!(await prisma.team.findUnique({ where: { id: d.teamId } }))) {
      return reply.code(404).send({ error: '所属团队不存在' });
    }
    const [c1, c2] = pickPalette(d.name);
    const emp = await prisma.employee.create({
      data: {
        teamId: d.teamId,
        name: d.name,
        title: d.title,
        iconKey: d.iconKey || null,
        color1: d.color1 || c1,
        color2: d.color2 || c2,
        score: d.score || 0,
        ratingCount: d.count || 0,
        dist: JSON.stringify(d.dist || Array(10).fill(0)),
        sort: d.sort ?? 0,
      },
    });
    return { employee: serEmployee(emp) };
  });

  app.put('/employees/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = employeeSchema.partial().safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    if (d.iconKey && !(await checkIcon(d.iconKey, 'employee', reply))) return;
    if (!(await prisma.employee.findUnique({ where: { id } }))) {
      return reply.code(404).send({ error: '员工不存在' });
    }

    const data: any = {};
    if (d.teamId !== undefined) data.teamId = d.teamId;
    if (d.name !== undefined) data.name = d.name;
    if (d.title !== undefined) data.title = d.title;
    if (d.iconKey !== undefined) data.iconKey = d.iconKey;
    if (d.color1 !== undefined) data.color1 = d.color1;
    if (d.color2 !== undefined) data.color2 = d.color2;
    if (d.score !== undefined) data.score = d.score;
    if (d.count !== undefined) data.ratingCount = d.count;
    if (d.dist !== undefined) data.dist = JSON.stringify(d.dist);
    if (d.sort !== undefined) data.sort = d.sort;

    const emp = await prisma.employee.update({ where: { id }, data });
    return { employee: serEmployee(emp) };
  });

  app.delete('/employees/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const emp = await prisma.employee.findUnique({ where: { id } });
    if (!emp) {
      return reply.code(404).send({ error: '员工不存在' });
    }
    await prisma.needMember.deleteMany({ where: { employeeId: id } });
    await purgeTargets([{ type: 'employee', ids: [id] }]);
    await prisma.employee.delete({ where: { id } });
    /* 删除员工后其评分已清理，团队合并分需要重算 */
    await recalcTeamScore(prisma, emp.teamId);
    return { ok: true };
  });

  /* ========== 需求 ========== */
  app.get('/needs', async () => {
    const needs = await prisma.need.findMany({
      include: { team: true },
      orderBy: [{ sort: 'asc' }, { id: 'asc' }],
    });
    const ids = needs.map(n => n.id);
    const members = ids.length
      ? await prisma.needMember.findMany({ where: { needId: { in: ids } }, orderBy: { sort: 'asc' } })
      : [];
    const empIds = [...new Set(members.map(m => m.employeeId))];
    const emps = empIds.length
      ? await prisma.employee.findMany({ where: { id: { in: empIds } } })
      : [];
    const empMap = new Map(emps.map(e => [e.id, e]));

    return {
      needs: needs.map(n => ({
        ...serNeed(n),
        membersDetail: members
          .filter(m => m.needId === n.id)
          .map(m => {
            const e = empMap.get(m.employeeId);
            return e
              ? { employeeId: e.id, role: m.role, name: e.name, teamId: e.teamId }
              : null;
          })
          .filter(Boolean),
      })),
    };
  });

  app.post('/needs', async (req, reply) => {
    const parsed = needSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    const need = await prisma.need.create({
      data: {
        title: d.title,
        desc: d.desc,
        category: d.category,
        status: d.status,
        teamId: d.teamId || null,
        proposerName: d.proposerName || null,
        tags: JSON.stringify(d.tags || []),
        score: d.score || 0,
        voteCount: d.count || 0,
        dist: JSON.stringify(d.dist || Array(10).fill(0)),
        sort: d.sort ?? 0,
      },
      include: { team: true },
    });
    if (d.members?.length) {
      await prisma.needMember.createMany({
        data: d.members.map((m, i) => ({ needId: need.id, employeeId: m.employeeId, role: m.role, sort: i })),
      });
    }
    return { need: serNeed(need) };
  });

  app.put('/needs/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = needSchema.partial().safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    if (!(await prisma.need.findUnique({ where: { id } }))) {
      return reply.code(404).send({ error: '需求不存在' });
    }

    const data: any = {};
    if (d.title !== undefined) data.title = d.title;
    if (d.desc !== undefined) data.desc = d.desc;
    if (d.category !== undefined) data.category = d.category;
    if (d.status !== undefined) data.status = d.status;
    if (d.teamId !== undefined) data.teamId = d.teamId || null;
    if (d.proposerName !== undefined) data.proposerName = d.proposerName || null;
    if (d.tags !== undefined) data.tags = JSON.stringify(d.tags);
    if (d.score !== undefined) data.score = d.score;
    if (d.count !== undefined) data.voteCount = d.count;
    if (d.dist !== undefined) data.dist = JSON.stringify(d.dist);
    if (d.sort !== undefined) data.sort = d.sort;

    const need = await prisma.need.update({ where: { id }, data, include: { team: true } });
    if (d.members) {
      const beforeMembers = await prisma.needMember.findMany({
        where: { needId: id },
        select: { employeeId: true },
      });
      await prisma.needMember.deleteMany({ where: { needId: id } });
      if (d.members.length) {
        await prisma.needMember.createMany({
          data: d.members.map((m, i) => ({ needId: id, employeeId: m.employeeId, role: m.role, sort: i })),
        });
      }
      const afterIds = new Set(d.members.map(m => m.employeeId));
      const removed = beforeMembers.map(m => m.employeeId).filter(eid => !afterIds.has(eid));
      if (removed.length) await purgeNeedScopedRatings(prisma, id, removed);
      /* 管理端显式设置了展示分时以手工值为准，否则按真实评分重算 */
      if (d.score === undefined) await recalcNeedScore(prisma, id);
    }
    return { need: serNeed(need) };
  });

  app.delete('/needs/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const need = await prisma.need.findUnique({ where: { id } });
    if (!need) {
      return reply.code(404).send({ error: '需求不存在' });
    }
    await prisma.needMember.deleteMany({ where: { needId: id } });
    /* 需求内成员表现分（targetType=employee + scope）不在 purgeTargets 的范围内 */
    await purgeNeedScopedRatings(prisma, id);
    await purgeTargets([{ type: 'need', ids: [id] }]);
    await prisma.need.delete({ where: { id } });
    await removeUploadedImages(parseImages(need.images));
    return { ok: true };
  });

  /* ========== 评论 ========== */
  app.get('/comments', async req => {
    const { targetType, targetId } = req.query as any;
    const comments = await prisma.comment.findMany({
      where: {
        ...(targetType ? { targetType: String(targetType) } : {}),
        ...(targetId ? { targetId: Number(targetId) } : {}),
      },
      include: { user: true, parent: { include: { user: true } } },
      orderBy: { id: 'desc' },
      take: 100,
    });
    return {
      comments: comments.map(c => ({
        ...serComment(c, c.parent?.user?.nickname ?? null),
        targetType: c.targetType,
        targetId: c.targetId,
        username: c.user ? c.user.username : '',
      })),
    };
  });

  app.delete('/comments/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    if (!(await prisma.comment.findUnique({ where: { id } }))) {
      return reply.code(404).send({ error: '评论不存在' });
    }
    /* 连同其下回复的通知一起清理，避免消息中心残留点不开的提醒 */
    const children = await prisma.comment.findMany({
      where: { parentId: id },
      select: { id: true },
    });
    const ids = [id, ...children.map(c => c.id)];
    await prisma.notification.deleteMany({ where: { commentId: { in: ids } } });
    await prisma.comment.delete({ where: { id } });
    return { ok: true };
  });

  /* ========== 动态 ========== */
  app.get('/posts', async req => {
    const { userId } = req.query as any;
    const posts = await prisma.post.findMany({
      where: userId ? { userId: Number(userId) } : undefined,
      include: { user: true },
      orderBy: { id: 'desc' },
      take: 100,
    });
    return {
      posts: posts.map(p => ({
        ...serPost(p),
        userId: p.userId,
        username: p.user ? p.user.username : '',
      })),
    };
  });

  app.delete('/posts/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const post = await prisma.post.findUnique({ where: { id } });
    if (!post) return reply.code(404).send({ error: '动态不存在' });
    /* 评论与通知为多态关联，无外键，删除动态时手动清理 */
    await prisma.comment.deleteMany({ where: { targetType: 'post', targetId: id } });
    await prisma.notification.deleteMany({ where: { targetType: 'post', targetId: id } });
    await prisma.post.delete({ where: { id } });
    let images: string[] = [];
    try {
      const v = JSON.parse(post.images);
      if (Array.isArray(v)) images = v.filter((x: any) => typeof x === 'string');
    } catch {
      images = [];
    }
    await removeUploadedImages(images);
    return { ok: true };
  });

  /* ========== 图标 ========== */
  const iconSchema = z.object({
    key: z.string().min(2).max(32).regex(/^[a-z0-9_-]+$/, 'key 只能包含小写字母、数字、_、-'),
    kind: z.enum(['team', 'employee', 'user']),
    name: z.string().min(1).max(20),
    svg: z.string().min(20, 'SVG 内容过短').max(20000),
    sort: z.number().int().optional(),
  });

  app.post('/icons', async (req, reply) => {
    const parsed = iconSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    if (!/<svg[\s>]/i.test(parsed.data.svg)) {
      return reply.code(400).send({ error: 'SVG 内容必须以 <svg> 开头' });
    }
    if (await prisma.icon.findUnique({ where: { key: parsed.data.key } })) {
      return reply.code(409).send({ error: '图标 key 已存在' });
    }
    const icon = await prisma.icon.create({
      data: { key: parsed.data.key, kind: parsed.data.kind, name: parsed.data.name, svg: parsed.data.svg, sort: parsed.data.sort ?? 99 },
    });
    return { icon: serIcon(icon) };
  });

  app.put('/icons/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const schema = z.object({
      name: z.string().min(1).max(20).optional(),
      svg: z.string().min(20).max(20000).optional(),
      sort: z.number().int().optional(),
    });
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    if (parsed.data.svg && !/<svg[\s>]/i.test(parsed.data.svg)) {
      return reply.code(400).send({ error: 'SVG 内容必须以 <svg> 开头' });
    }
    if (!(await prisma.icon.findUnique({ where: { id } }))) {
      return reply.code(404).send({ error: '图标不存在' });
    }
    const icon = await prisma.icon.update({ where: { id }, data: parsed.data });
    return { icon: serIcon(icon) };
  });

  app.delete('/icons/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const icon = await prisma.icon.findUnique({ where: { id } });
    if (!icon) return reply.code(404).send({ error: '图标不存在' });
    const [teamUse, empUse, userUse] = await Promise.all([
      prisma.team.count({ where: { iconKey: icon.key } }),
      prisma.employee.count({ where: { iconKey: icon.key } }),
      prisma.user.count({ where: { avatarIcon: icon.key } }),
    ]);
    if (teamUse + empUse + userUse > 0) {
      return reply.code(409).send({ error: '该图标正在使用中，无法删除' });
    }
    await prisma.icon.delete({ where: { id } });
    return { ok: true };
  });

  /* ========== 用户 ========== */
  app.get('/users', async () => {
    const users = await prisma.user.findMany({
      orderBy: { id: 'asc' },
      select: { id: true, username: true, nickname: true, role: true, avatarIcon: true, createdAt: true },
    });
    return { users };
  });
}
