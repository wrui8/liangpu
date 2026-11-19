import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import { optionalAuth, requireAuth } from '../auth';
import {
  serTeam,
  serEmployee,
  serNeed,
  loadComments,
  parseImages,
} from '../serialize';
import { removeUploadedImages, saveImageDataUrl } from '../uploads';
import { purgeNeedScopedRatings, recalcNeedScore } from '../needScore';
import { round1 } from '../utils';

function serIcon(i: any) {
  return { id: i.id, key: i.key, kind: i.kind, name: i.name, svg: i.svg, sort: i.sort };
}

/* 用户自行发布需求：状态固定「评审中」，评分与排序由平台打分/管理端决定 */
const needMemberInput = z.object({
  employeeId: z.number().int().positive(),
  role: z.enum(['提议', '负责', '参与']).default('参与'),
});

const needInput = z.object({
  title: z.string().trim().min(1, '请填写需求标题').max(60, '标题最多 60 字'),
  desc: z.string().trim().min(1, '请填写需求描述').max(1000, '描述最多 1000 字'),
  category: z.string().trim().min(1, '请填写分类').max(16, '分类最多 16 字'),
  teamId: z.number().int().positive().nullable().optional(),
  tags: z.array(z.string().max(12)).max(6, '最多 6 个标签').optional(),
  members: z.array(needMemberInput).max(20, '最多关联 20 位员工').optional(),
  images: z.array(z.string().max(8 * 1024 * 1024)).max(4, '最多上传 4 张图片').optional(),
});

function cleanTags(tags: string[] | undefined): string[] {
  return [...new Set((tags ?? []).map(t => t.trim()).filter(Boolean))].slice(0, 6);
}

/* 发布频控：单个用户一小时最多发布 5 条需求（内存计数，重启清零） */
const NEED_RATE_WINDOW_MS = 60 * 60 * 1000;
const NEED_RATE_LIMIT = 5;
const needPostLog = new Map<number, number[]>();

function hitNeedRate(userId: number): boolean {
  const now = Date.now();
  const from = now - NEED_RATE_WINDOW_MS;
  const recent = (needPostLog.get(userId) ?? []).filter(t => t > from);
  if (recent.length >= NEED_RATE_LIMIT) {
    needPostLog.set(userId, recent);
    return false;
  }
  recent.push(now);
  needPostLog.set(userId, recent);
  return true;
}

/**
 * 需求配图：data URL 落盘为新文件，/uploads/ 地址视为编辑时保留的旧图。
 * 任一张失败会清理本次已写入的文件后抛错。
 */
async function resolveNeedImages(images: string[]): Promise<string[]> {
  const saved: string[] = [];
  try {
    const out: string[] = [];
    for (const img of images) {
      if (img.startsWith('data:')) {
        const url = await saveImageDataUrl(img);
        saved.push(url);
        out.push(url);
      } else if (img.startsWith('/uploads/') && !img.includes('..')) {
        out.push(img);
      } else {
        throw new Error('图片地址不合法');
      }
    }
    return out;
  } catch (e) {
    await removeUploadedImages(saved);
    throw e;
  }
}

/** 校验归属团队与相关员工确实存在；失败时已写入 reply */
async function checkNeedRefs(
  teamId: number | null | undefined,
  members: Array<{ employeeId: number }> | undefined,
  reply: any,
): Promise<boolean> {
  if (teamId != null && !(await prisma.team.findUnique({ where: { id: teamId } }))) {
    reply.code(400).send({ error: '归属团队不存在' });
    return false;
  }
  if (members?.length) {
    const ids = members.map(m => m.employeeId);
    if (new Set(ids).size !== ids.length) {
      reply.code(400).send({ error: '相关员工不能重复' });
      return false;
    }
    const count = await prisma.employee.count({ where: { id: { in: ids } } });
    if (count !== ids.length) {
      reply.code(400).send({ error: '相关员工不存在' });
      return false;
    }
  }
  return true;
}

export async function catalogRoutes(app: FastifyInstance) {
  /* 公开接口：带 token 时识别用户，用于返回点赞状态 */
  app.addHook('preHandler', optionalAuth);

  /* 图标池：team / employee / user */
  app.get('/icons', async req => {
    const kind = (req.query as any).kind as string | undefined;
    const icons = await prisma.icon.findMany({
      where: kind ? { kind } : undefined,
      orderBy: [{ kind: 'asc' }, { sort: 'asc' }],
    });
    return { icons: icons.map(serIcon) };
  });

  /* 团队列表 */
  app.get('/teams', async req => {
    const { category, keyword } = req.query as any;
    const teams = await prisma.team.findMany({
      where: {
        ...(category && category !== '全部' ? { category } : {}),
        ...(keyword ? { name: { contains: String(keyword) } } : {}),
      },
      include: { _count: { select: { employees: true } } },
      orderBy: [{ sort: 'asc' }, { id: 'asc' }],
    });
    return {
      teams: teams.map(t => ({ ...serTeam(t), employeeCount: t._count.employees })),
    };
  });

  /* 团队详情 */
  app.get('/teams/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const team = await prisma.team.findUnique({
      where: { id },
      include: { employees: { orderBy: [{ sort: 'asc' }, { id: 'asc' }] } },
    });
    if (!team) return reply.code(404).send({ error: '团队不存在' });
    const comments = await loadComments(prisma, 'team', id, req.user?.id);
    return {
      team: { ...serTeam(team), employeeCount: team.employees.length },
      employees: team.employees.map(serEmployee),
      comments,
    };
  });

  /* 员工列表：发布需求时选择「相关员工」 */
  app.get('/employees', async req => {
    const { teamId, keyword } = req.query as any;
    const employees = await prisma.employee.findMany({
      where: {
        ...(teamId ? { teamId: Number(teamId) } : {}),
        ...(keyword ? { name: { contains: String(keyword) } } : {}),
      },
      include: { team: true },
      orderBy: [{ teamId: 'asc' }, { sort: 'asc' }, { id: 'asc' }],
    });
    return {
      employees: employees.map(e => ({ ...serEmployee(e), teamName: e.team.name })),
    };
  });

  /* 员工详情 */
  app.get('/employees/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const emp = await prisma.employee.findUnique({ where: { id }, include: { team: true } });
    if (!emp) return reply.code(404).send({ error: '员工不存在' });
    const comments = await loadComments(prisma, 'employee', id, req.user?.id);

    /* 该员工在各需求中的表现分（与全局分隔离，只展示仍在该需求成员中的评分） */
    const needMembers = await prisma.needMember.findMany({
      where: { employeeId: id },
      select: { needId: true },
    });
    const needIds = needMembers.map(m => m.needId);
    const scopedRatings = needIds.length
      ? await prisma.rating.findMany({
          where: {
            targetType: 'employee',
            targetId: id,
            scopeType: 'need',
            scopeId: { in: needIds },
          },
          select: { scopeId: true, userId: true, score: true, updatedAt: true },
        })
      : [];
    const needRows = needIds.length
      ? await prisma.need.findMany({ where: { id: { in: needIds } } })
      : [];
    const myId = req.user?.id;
    const agg = new Map<number, { sum: number; count: number; my: number | null; last: number }>();
    for (const r of scopedRatings) {
      const cur = agg.get(r.scopeId) ?? { sum: 0, count: 0, my: null, last: 0 };
      cur.sum += r.score;
      cur.count += 1;
      if (myId != null && r.userId === myId) cur.my = r.score;
      cur.last = Math.max(cur.last, r.updatedAt.getTime());
      agg.set(r.scopeId, cur);
    }
    const needScores = needRows
      .map(n => {
        const a = agg.get(n.id);
        if (!a || a.count === 0) return null;
        return {
          needId: n.id,
          title: n.title,
          status: n.status,
          score: round1(a.sum / a.count),
          count: a.count,
          myScore: a.my,
          updatedAt: new Date(a.last),
        };
      })
      .filter(Boolean)
      .sort((x: any, y: any) => y.updatedAt - x.updatedAt);

    return {
      employee: { ...serEmployee(emp), teamName: emp.team.name },
      team: serTeam(emp.team),
      comments,
      needScores,
    };
  });

  /* 需求列表 */
  app.get('/needs', async req => {
    const { status } = req.query as any;
    const needs = await prisma.need.findMany({
      where: status && status !== '全部' ? { status } : {},
      include: { team: true },
      orderBy: [{ sort: 'asc' }, { id: 'asc' }],
    });

    const ids = needs.map(n => n.id);
    const members = ids.length
      ? await prisma.needMember.findMany({
          where: { needId: { in: ids } },
          orderBy: { sort: 'asc' },
        })
      : [];
    const empIds = [...new Set(members.map(m => m.employeeId))];
    const emps = empIds.length
      ? await prisma.employee.findMany({ where: { id: { in: empIds } } })
      : [];
    const empMap = new Map(emps.map(e => [e.id, e]));

    return {
      needs: needs.map(n => ({
        ...serNeed(n),
        members: members
          .filter(m => m.needId === n.id)
          .map(m => {
            const e = empMap.get(m.employeeId);
            return e
              ? { employeeId: e.id, role: m.role, name: e.name, short: e.name.slice(0, 1), color1: e.color1, color2: e.color2, iconKey: e.iconKey }
              : null;
          })
          .filter(Boolean),
      })),
    };
  });

  /* 需求详情 */
  app.get('/needs/:id', async (req, reply) => {
    const id = Number((req.params as any).id);
    const need = await prisma.need.findUnique({ where: { id }, include: { team: true } });
    if (!need) return reply.code(404).send({ error: '需求不存在' });

    const members = await prisma.needMember.findMany({ where: { needId: id }, orderBy: { sort: 'asc' } });
    const empIds = members.map(m => m.employeeId);
    const emps = empIds.length
      ? await prisma.employee.findMany({ where: { id: { in: empIds } }, include: { team: true } })
      : [];
    const empMap = new Map(emps.map(e => [e.id, e]));

    /* 需求内成员表现分：只在该需求维度统计，与员工全局分隔离 */
    const scoped = empIds.length
      ? await prisma.rating.findMany({
          where: {
            targetType: 'employee',
            scopeType: 'need',
            scopeId: id,
            targetId: { in: empIds },
          },
          select: { targetId: true, userId: true, score: true },
        })
      : [];
    const myId = req.user?.id;
    const scoreMap = new Map<number, { sum: number; count: number; my: number | null }>();
    for (const r of scoped) {
      const cur = scoreMap.get(r.targetId) ?? { sum: 0, count: 0, my: null };
      cur.sum += r.score;
      cur.count += 1;
      if (myId != null && r.userId === myId) cur.my = r.score;
      scoreMap.set(r.targetId, cur);
    }

    const comments = await loadComments(prisma, 'need', id, req.user?.id);

    return {
      need: serNeed(need),
      members: members
        .map(m => {
          const e = empMap.get(m.employeeId);
          if (!e) return null;
          const s = scoreMap.get(e.id);
          return {
            role: m.role,
            employee: { ...serEmployee(e), teamName: e.team.name },
            needScore: s ? round1(s.sum / s.count) : 0,
            needCount: s?.count ?? 0,
            myScore: s?.my ?? null,
          };
        })
        .filter(Boolean),
      comments,
    };
  });

  /* ========== 用户发布需求 ========== */

  /** 发布需求：直接进入「评审中」，评分初始为 0，等待全员打分 */
  app.post('/needs', { preHandler: requireAuth }, async (req, reply) => {
    const parsed = needInput.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    const me = req.user!;

    if (!hitNeedRate(me.id)) {
      return reply
        .code(429)
        .send({ error: '发布太频繁了，请稍后再试（每小时最多 5 条）' });
    }
    if (!(await checkNeedRefs(d.teamId, d.members, reply))) return;

    let images: string[];
    try {
      images = await resolveNeedImages(d.images ?? []);
    } catch (e: any) {
      return reply.code(400).send({ error: e?.message || '图片上传失败' });
    }

    try {
      const need = await prisma.need.create({
        data: {
          title: d.title,
          desc: d.desc,
          category: d.category,
          status: '评审中',
          teamId: d.teamId || null,
          proposerName: me.nickname ? me.nickname.slice(0, 20) : null,
          proposerId: me.id,
          images: JSON.stringify(images),
          tags: JSON.stringify(cleanTags(d.tags)),
          score: 0,
          voteCount: 0,
          dist: JSON.stringify(Array(10).fill(0)),
          sort: 0,
        },
        include: { team: true },
      });
      if (d.members?.length) {
        await prisma.needMember.createMany({
          data: d.members.map((m, i) => ({
            needId: need.id,
            employeeId: m.employeeId,
            role: m.role,
            sort: i,
          })),
        });
      }
      return { need: serNeed(need) };
    } catch (e) {
      await removeUploadedImages(images);
      throw e;
    }
  });

  /** 编辑需求：仅发布者本人或管理员；状态与评分数据只能由管理端维护 */
  app.put('/needs/:id', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = needInput.partial().safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const d = parsed.data;
    const me = req.user!;

    const need = await prisma.need.findUnique({ where: { id } });
    if (!need) return reply.code(404).send({ error: '需求不存在' });
    if (need.proposerId !== me.id && me.role !== 'admin') {
      return reply.code(403).send({ error: '只能编辑自己发布的需求' });
    }
    if (!(await checkNeedRefs(d.teamId, d.members, reply))) return;

    const data: any = {};
    if (d.title !== undefined) data.title = d.title;
    if (d.desc !== undefined) data.desc = d.desc;
    if (d.category !== undefined) data.category = d.category;
    if (d.teamId !== undefined) data.teamId = d.teamId || null;
    if (d.tags !== undefined) data.tags = JSON.stringify(cleanTags(d.tags));

    const before = parseImages(need.images);
    let after: string[] | null = null;
    if (d.images !== undefined) {
      try {
        after = await resolveNeedImages(d.images);
      } catch (e: any) {
        return reply.code(400).send({ error: e?.message || '图片上传失败' });
      }
      data.images = JSON.stringify(after);
    }

    let updated;
    try {
      updated = await prisma.need.update({ where: { id }, data, include: { team: true } });
    } catch (e) {
      if (after) await removeUploadedImages(after.filter(x => !before.includes(x)));
      throw e;
    }

    if (after) {
      await removeUploadedImages(before.filter(x => !after!.includes(x)));
    }
    if (d.members) {
      const beforeMembers = await prisma.needMember.findMany({
        where: { needId: id },
        select: { employeeId: true },
      });
      await prisma.needMember.deleteMany({ where: { needId: id } });
      if (d.members.length) {
        await prisma.needMember.createMany({
          data: d.members.map((m, i) => ({
            needId: id,
            employeeId: m.employeeId,
            role: m.role,
            sort: i,
          })),
        });
      }
      /* 被移出需求的成员，其在本需求下的评分与短评一并清理，再重算总分 */
      const afterIds = new Set(d.members.map(m => m.employeeId));
      const removed = beforeMembers
        .map(m => m.employeeId)
        .filter(eid => !afterIds.has(eid));
      if (removed.length) await purgeNeedScopedRatings(prisma, id, removed);
      await recalcNeedScore(prisma, id);
    }
    return { need: serNeed(updated) };
  });

  /** 删除需求：仅发布者本人或管理员；连带清理成员、评分、评论、通知与配图 */
  app.delete('/needs/:id', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const need = await prisma.need.findUnique({ where: { id } });
    if (!need) return reply.code(404).send({ error: '需求不存在' });
    const me = req.user!;
    if (need.proposerId !== me.id && me.role !== 'admin') {
      return reply.code(403).send({ error: '只能删除自己发布的需求' });
    }

    await prisma.needMember.deleteMany({ where: { needId: id } });
    await purgeNeedScopedRatings(prisma, id);
    await prisma.rating.deleteMany({ where: { targetType: 'need', targetId: id } });
    await prisma.comment.deleteMany({ where: { targetType: 'need', targetId: id } });
    await prisma.notification.deleteMany({ where: { targetType: 'need', targetId: id } });
    await prisma.need.delete({ where: { id } });
    await removeUploadedImages(parseImages(need.images));
    return { ok: true };
  });
}
