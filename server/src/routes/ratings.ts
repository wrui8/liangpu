import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../auth';
import { serComment } from '../serialize';
import { notify } from '../notify';
import { recalcTeamScore } from '../teamScore';
import { recalcNeedScore } from '../needScore';
import { parseDist, distPercent, round1 } from '../utils';

type TT = 'team' | 'employee' | 'need';

const ratingSchema = z.object({
  targetType: z.enum(['team', 'employee', 'need']),
  targetId: z.number().int().positive(),
  /** 评分维度：目前仅支持 need（需求内成员表现分） */
  scopeType: z.enum(['need']).optional(),
  scopeId: z.number().int().positive().optional(),
  score: z.number().int().min(1).max(10),
  content: z.string().trim().max(120).optional(),
});

async function findTarget(type: TT, id: number) {
  if (type === 'team') return prisma.team.findUnique({ where: { id } });
  if (type === 'employee') return prisma.employee.findUnique({ where: { id } });
  return prisma.need.findUnique({ where: { id } });
}

export async function ratingRoutes(app: FastifyInstance) {
  app.post('/ratings', { preHandler: requireAuth }, async (req, reply) => {
    const parsed = ratingSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const { targetType, targetId, score, content } = parsed.data;
    const userId = req.user.id;

    /* 需求维度：成员表现分只属于该需求，不进入员工全局分与团队分 */
    let scopeType = '';
    let scopeId = 0;
    if (parsed.data.scopeType !== undefined || parsed.data.scopeId !== undefined) {
      if (parsed.data.scopeType !== 'need' || !parsed.data.scopeId) {
        return reply.code(400).send({ error: '评分维度参数不完整' });
      }
      if (targetType !== 'employee') {
        return reply.code(400).send({ error: '只有成员可以按需求维度评分' });
      }
      const member = await prisma.needMember.findUnique({
        where: {
          needId_employeeId: {
            needId: parsed.data.scopeId,
            employeeId: targetId,
          },
        },
      });
      if (!member) return reply.code(400).send({ error: '该员工不在此需求的相关员工中' });
      scopeType = 'need';
      scopeId = parsed.data.scopeId;
    }

    const target: any = await findTarget(targetType, targetId);
    if (!target) return reply.code(404).send({ error: '评分对象不存在' });

    const unique = { userId, targetType, scopeType, scopeId, targetId };
    const existing = await prisma.rating.findUnique({
      where: { userId_targetType_scopeType_scopeId_targetId: unique },
    });

    /* ===== 需求内成员评分 ===== */
    if (scopeType === 'need') {
      await prisma.$transaction(async tx => {
        await tx.rating.upsert({
          where: { userId_targetType_scopeType_scopeId_targetId: unique },
          create: { ...unique, score },
          update: { score },
        });
        if (content) {
          const old = await tx.comment.findFirst({
            where: { userId, targetType, targetId, scopeType, scopeId },
          });
          if (old) {
            await tx.comment.update({ where: { id: old.id }, data: { score, content } });
          } else {
            await tx.comment.create({
              data: { userId, targetType, targetId, score, content, scopeType, scopeId },
            });
          }
        }
        await recalcNeedScore(tx, scopeId);
      });

      const agg = await prisma.rating.aggregate({
        where: { targetType, targetId, scopeType, scopeId },
        _avg: { score: true },
        _count: { _all: true },
      });
      return {
        ok: true,
        score: round1(agg._avg.score ?? 0),
        count: agg._count._all,
        dist: distPercent(Array(10).fill(0)),
        updated: Boolean(existing),
      };
    }

    /* ===== 全局评分 ===== */
    const count: number = targetType === 'need' ? target.voteCount : target.ratingCount;
    const dist = parseDist(target.dist);
    const nextDist = [...dist];
    if (existing) nextDist[existing.score - 1] = Math.max(0, nextDist[existing.score - 1] - 1);
    nextDist[score - 1] += 1;
    const nextCount = existing ? count : count + 1;
    const nextScore = existing
      ? count > 0
        ? (target.score * count - existing.score + score) / count
        : score
      : (target.score * count + score) / nextCount;

    await prisma.$transaction(async tx => {
      await tx.rating.upsert({
        where: { userId_targetType_scopeType_scopeId_targetId: unique },
        create: { ...unique, score },
        update: { score },
      });

      if (targetType === 'team') {
        /* 团队分 = 团队直接评分 + 全部员工全局评分，合并重算 */
        await recalcTeamScore(tx, targetId);
      } else if (targetType === 'employee') {
        await tx.employee.update({
          where: { id: targetId },
          data: { dist: JSON.stringify(nextDist), score: nextScore, ratingCount: nextCount },
        });
        /* 员工全局评分会改变所属团队的合并分 */
        await recalcTeamScore(tx, target.teamId);
      } else {
        /* 需求自身评分：总分 = 自身 70% + 成员表现 30%，统一由 recalcNeedScore 写入 */
        await recalcNeedScore(tx, targetId);
      }

      if (content) {
        const old = await tx.comment.findFirst({
          where: { userId, targetType, targetId, scopeType: '', scopeId: 0 },
        });
        if (old) {
          await tx.comment.update({ where: { id: old.id }, data: { score, content } });
        } else {
          await tx.comment.create({ data: { userId, targetType, targetId, score, content } });
        }
      }
    });

    if (targetType === 'team') {
      /* 返回合并后的团队数据（含员工评分） */
      const team = await prisma.team.findUnique({ where: { id: targetId } });
      return {
        ok: true,
        score: round1(team?.score ?? 0),
        count: team?.ratingCount ?? 0,
        dist: distPercent(parseDist(team?.dist)),
        updated: Boolean(existing),
      };
    }

    if (targetType === 'need') {
      const n = await prisma.need.findUnique({ where: { id: targetId } });
      return {
        ok: true,
        score: round1(n?.score ?? 0),
        count: n?.voteCount ?? 0,
        dist: distPercent(parseDist(n?.dist)),
        updated: Boolean(existing),
      };
    }

    return {
      ok: true,
      score: round1(nextScore),
      count: nextCount,
      dist: distPercent(nextDist),
      updated: Boolean(existing),
    };
  });

  app.post('/comments/:id/like', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const userId = req.user.id;
    const comment = await prisma.comment.findUnique({ where: { id } });
    if (!comment) return reply.code(404).send({ error: '评论不存在' });

    const existing = await prisma.commentLike.findUnique({
      where: { userId_commentId: { userId, commentId: id } },
    });

    let liked: boolean;
    let likes: number;
    if (existing) {
      await prisma.$transaction([
        prisma.commentLike.delete({ where: { id: existing.id } }),
        prisma.comment.update({ where: { id }, data: { likes: { decrement: 1 } } }),
      ]);
      liked = false;
      likes = Math.max(0, comment.likes - 1);
    } else {
      await prisma.$transaction([
        prisma.commentLike.create({ data: { userId, commentId: id } }),
        prisma.comment.update({ where: { id }, data: { likes: { increment: 1 } } }),
      ]);
      liked = true;
      likes = comment.likes + 1;
    }
    /* 只有点赞成功才通知作者，取消点赞不产生通知 */
    if (liked) {
      await notify({
        userId: comment.userId,
        actorId: userId,
        type: 'like_comment',
        targetType: comment.targetType,
        targetId: comment.targetId,
        commentId: comment.id,
        preview: comment.content,
      });
    }
    return { liked, likes };
  });

  /** 回复亮评：支持回复任意层级的评论（回复的回复） */
  app.post('/comments/:id/reply', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = z
      .object({ content: z.string().trim().min(1, '回复内容不能为空').max(120, '回复最多 120 字') })
      .safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });

    const parent = await prisma.comment.findUnique({ where: { id }, include: { user: true } });
    if (!parent) return reply.code(404).send({ error: '评论不存在' });

    /* 向上找到根评论：旧数据可能没有 rootId，按 parentId 逐级回溯 */
    let root: any = parent;
    let guard = 0;
    while (root.parentId != null && guard++ < 64) {
      if (root.rootId) {
        const r = await prisma.comment.findUnique({ where: { id: root.rootId } });
        if (r) root = r;
        break;
      }
      const p = await prisma.comment.findUnique({ where: { id: root.parentId } });
      if (!p) break;
      root = p;
    }

    const created = await prisma.comment.create({
      data: {
        userId: req.user.id,
        targetType: root.targetType,
        targetId: root.targetId,
        /* 回复继承根评论的维度，需求内短评的回复不会混进全局评论区 */
        scopeType: root.scopeType ?? '',
        scopeId: root.scopeId ?? 0,
        score: root.score,
        content: parsed.data.content,
        parentId: parent.id,
        rootId: root.id,
        replyToUserId: parent.userId,
      },
      include: {
        user: true,
        likesBy: { where: { userId: req.user.id }, select: { id: true } },
      },
    });
    /* 通知被回复的那条评论的作者（自己是作者时不通知） */
    await notify({
      userId: parent.userId,
      actorId: req.user.id,
      type: 'reply_comment',
      targetType: root.targetType,
      targetId: root.targetId,
      commentId: created.id,
      preview: created.content,
    });
    return { comment: serComment(created, parent.user?.nickname ?? null) };
  });
}
