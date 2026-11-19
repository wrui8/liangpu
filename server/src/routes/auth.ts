import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../auth';

const regSchema = z.object({
  username: z.string().min(3, '用户名至少 3 位').max(24).regex(/^[a-zA-Z0-9_]+$/, '用户名只能包含字母、数字、下划线'),
  password: z.string().min(6, '密码至少 6 位').max(64),
  nickname: z.string().min(1, '请填写昵称').max(16),
});

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

export function serUser(u: any) {
  return {
    id: u.id,
    username: u.username,
    nickname: u.nickname,
    role: u.role,
    avatarIcon: u.avatarIcon,
    createdAt: u.createdAt,
  };
}

export async function authRoutes(app: FastifyInstance) {
  app.post('/auth/register', async (req, reply) => {
    const parsed = regSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const { username, password, nickname } = parsed.data;

    if (await prisma.user.findUnique({ where: { username } })) {
      return reply.code(409).send({ error: '用户名已存在' });
    }
    const user = await prisma.user.create({
      data: { username, password: await bcrypt.hash(password, 10), nickname },
    });
    const token = app.jwt.sign({
      id: user.id,
      username: user.username,
      nickname: user.nickname,
      role: user.role,
    });
    return { token, user: serUser(user) };
  });

  app.post('/auth/login', async (req, reply) => {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: '请填写用户名和密码' });
    const user = await prisma.user.findUnique({ where: { username: parsed.data.username } });
    if (!user || !(await bcrypt.compare(parsed.data.password, user.password))) {
      return reply.code(401).send({ error: '用户名或密码错误' });
    }
    const token = app.jwt.sign({
      id: user.id,
      username: user.username,
      nickname: user.nickname,
      role: user.role,
    });
    return { token, user: serUser(user) };
  });

  app.get('/me', { preHandler: requireAuth }, async req => {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    return { user: user ? serUser(user) : null };
  });

  app.patch('/me', { preHandler: requireAuth }, async (req, reply) => {
    const parsed = z
      .object({
        nickname: z.string().min(1).max(16).optional(),
        avatarIcon: z.string().optional(),
      })
      .safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: '参数不合法' });

    if (parsed.data.avatarIcon) {
      const icon = await prisma.icon.findUnique({ where: { key: parsed.data.avatarIcon } });
      if (!icon || icon.kind !== 'user') {
        return reply.code(400).send({ error: '该头像不在可选图标池中' });
      }
    }
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: parsed.data,
    });
    return { user: serUser(user) };
  });

  app.get('/me/ratings', { preHandler: requireAuth }, async req => {
    const ratings = await prisma.rating.findMany({
      where: { userId: req.user.id },
      orderBy: { updatedAt: 'desc' },
    });

    const teamIds = ratings.filter(r => r.targetType === 'team').map(r => r.targetId);
    const empIds = ratings.filter(r => r.targetType === 'employee').map(r => r.targetId);
    const needIds = ratings.filter(r => r.targetType === 'need').map(r => r.targetId);

    const [teams, emps, needs] = await Promise.all([
      prisma.team.findMany({ where: { id: { in: teamIds } } }),
      prisma.employee.findMany({ where: { id: { in: empIds } }, include: { team: true } }),
      prisma.need.findMany({ where: { id: { in: needIds } } }),
    ]);

    const teamMap = new Map(teams.map(t => [t.id, t]));
    const empMap = new Map(emps.map(e => [e.id, e]));
    const needMap = new Map(needs.map(n => [n.id, n]));

    /* 需求维度评分（需求内成员表现分）标注所属需求标题 */
    const scopeIds = [...new Set(ratings.filter(r => r.scopeType === 'need').map(r => r.scopeId))];
    const scopeNeeds = scopeIds.length
      ? await prisma.need.findMany({ where: { id: { in: scopeIds } } })
      : [];
    const scopeNeedMap = new Map(scopeNeeds.map(n => [n.id, n]));

    const out = ratings.map(r => {
      if (r.targetType === 'team') {
        const t = teamMap.get(r.targetId);
        return {
          targetType: r.targetType,
          targetId: r.targetId,
          score: r.score,
          name: t?.name ?? '已删除团队',
          iconKey: t?.iconKey ?? null,
          iconKind: 'team',
          color1: t?.color1 ?? '#8E9BFF',
          color2: t?.color2 ?? '#5B6CFF',
          updatedAt: r.updatedAt,
        };
      }
      if (r.targetType === 'employee') {
        const e = empMap.get(r.targetId);
        return {
          targetType: r.targetType,
          targetId: r.targetId,
          score: r.score,
          name: e?.name ?? '已删除员工',
          iconKey: e?.iconKey ?? null,
          iconKind: e?.iconKey ? 'employee' : 'letter',
          color1: e?.color1 ?? '#8E9BFF',
          color2: e?.color2 ?? '#5B6CFF',
          sub:
            r.scopeType === 'need'
              ? `需求：${scopeNeedMap.get(r.scopeId)?.title ?? '已删除需求'}`
              : (e?.team?.name ?? ''),
          scopeType: r.scopeType,
          scopeId: r.scopeId,
          updatedAt: r.updatedAt,
        };
      }
      const n = needMap.get(r.targetId);
      return {
        targetType: r.targetType,
        targetId: r.targetId,
        score: r.score,
        name: n?.title ?? '已删除需求',
        iconKey: null,
        iconKind: 'need',
        color1: '#FF7A45',
        color2: '#FF4D6D',
        updatedAt: r.updatedAt,
      };
    });

    return { ratings: out };
  });
}
