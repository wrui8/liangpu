import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { prisma } from '../db';
import { optionalAuth, requireAuth } from '../auth';
import { serPost, serComment, loadComments } from '../serialize';
import { notify } from '../notify';
import { removeUploadedImages, saveImageDataUrl } from '../uploads';

const postSchema = z.object({
  content: z.string().trim().min(1, '说点什么吧').max(500, '动态最多 500 字'),
  images: z.array(z.string().max(8 * 1024 * 1024)).max(4, '最多上传 4 张图片').optional(),
});

function parseImages(raw: any): string[] {
  try {
    const v = JSON.parse(String(raw || '[]'));
    return Array.isArray(v) ? v.filter(x => typeof x === 'string') : [];
  } catch {
    return [];
  }
}

function postInclude(myId?: number) {
  return {
    user: true,
    ...(myId ? { likesBy: { where: { userId: myId }, select: { id: true } } } : {}),
  } as any;
}

export async function postRoutes(app: FastifyInstance) {
  /**
   * 动态流。
   * - 平台级（不带 userId）：按点赞量降序、发送时间降序，点赞多且新的排前面；
   * - 用户级（带 userId）：按发送时间倒序，进入某位用户主页时使用。
   */
  app.get('/posts', { preHandler: optionalAuth }, async req => {
    const q = req.query as any;
    const userId = q.userId ? Number(q.userId) : undefined;
    const limit = Math.min(Math.max(Number(q.limit) || 30, 1), 100);
    const myId = req.user?.id;

    const posts = await prisma.post.findMany({
      where: userId ? { userId } : undefined,
      include: postInclude(myId),
      orderBy: userId
        ? [{ createdAt: 'desc' }, { id: 'desc' }]
        : [{ likes: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }],
      take: limit,
    });

    /* 各动态的根评论数（回复数不重复计入），一次分组查询完成 */
    const ids = posts.map(p => p.id);
    const groups = ids.length
      ? await prisma.comment.groupBy({
          by: ['targetId'],
          where: { targetType: 'post', targetId: { in: ids }, parentId: null },
          _count: { _all: true },
        })
      : [];
    const countMap = new Map(groups.map(g => [g.targetId, g._count._all]));
    return { posts: posts.map(p => serPost(p, countMap.get(p.id) ?? 0)) };
  });

  /** 发布动态（可配 base64 图片，最多 4 张） */
  app.post('/posts', { preHandler: requireAuth }, async (req, reply) => {
    const parsed = postSchema.safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });
    const { content, images } = parsed.data;

    const saved: string[] = [];
    try {
      for (const img of images ?? []) {
        saved.push(await saveImageDataUrl(img));
      }
    } catch (e: any) {
      await removeUploadedImages(saved);
      return reply.code(400).send({ error: e?.message || '图片上传失败' });
    }

    const post = await prisma.post.create({
      data: { userId: req.user.id, content, images: JSON.stringify(saved) },
      include: postInclude(req.user.id),
    });
    return { post: serPost(post) };
  });

  /** 点赞 / 取消点赞 */
  app.post('/posts/:id/like', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const userId = req.user.id;
    const post = await prisma.post.findUnique({ where: { id } });
    if (!post) return reply.code(404).send({ error: '动态不存在' });

    const existing = await prisma.postLike.findUnique({
      where: { userId_postId: { userId, postId: id } },
    });

    if (existing) {
      const [, updated] = await prisma.$transaction([
        prisma.postLike.delete({ where: { id: existing.id } }),
        prisma.post.update({ where: { id }, data: { likes: { decrement: 1 } } }),
      ]);
      return { liked: false, likes: Math.max(0, updated.likes) };
    }
    const [, updated] = await prisma.$transaction([
      prisma.postLike.create({ data: { userId, postId: id } }),
      prisma.post.update({ where: { id }, data: { likes: { increment: 1 } } }),
    ]);
    await notify({
      userId: post.userId,
      actorId: userId,
      type: 'like_post',
      targetType: 'post',
      targetId: id,
      preview: post.content,
    });
    return { liked: true, likes: updated.likes };
  });

  /** 动态详情：动态内容 + 评论区（根评论与全部后代回复） */
  app.get('/posts/:id', { preHandler: optionalAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const post = await prisma.post.findUnique({
      where: { id },
      include: postInclude(req.user?.id),
    });
    if (!post) return reply.code(404).send({ error: '动态不存在' });
    const comments = await loadComments(prisma, 'post', id, req.user?.id);
    return { post: serPost(post, comments.length), comments };
  });

  /** 评论动态（顶层评论；回复复用 /comments/:id/reply 的多层级体系） */
  app.post('/posts/:id/comment', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const parsed = z
      .object({ content: z.string().trim().min(1, '说点什么吧').max(120, '评论最多 120 字') })
      .safeParse(req.body);
    if (!parsed.success) return reply.code(400).send({ error: parsed.error.issues[0].message });

    const post = await prisma.post.findUnique({ where: { id } });
    if (!post) return reply.code(404).send({ error: '动态不存在' });

    const created = await prisma.comment.create({
      data: {
        userId: req.user.id,
        targetType: 'post',
        targetId: id,
        score: 0, // 动态评论不打分，客户端不显示分数标签
        content: parsed.data.content,
      },
      include: {
        user: true,
        likesBy: { where: { userId: req.user.id }, select: { id: true } },
      },
    });
    await notify({
      userId: post.userId,
      actorId: req.user.id,
      type: 'comment_post',
      targetType: 'post',
      targetId: id,
      commentId: created.id,
      preview: created.content,
    });
    return { comment: serComment(created) };
  });

  /** 删除动态：作者本人或管理员 */
  app.delete('/posts/:id', { preHandler: requireAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const post = await prisma.post.findUnique({ where: { id } });
    if (!post) return reply.code(404).send({ error: '动态不存在' });
    if (post.userId !== req.user.id && req.user.role !== 'admin') {
      return reply.code(403).send({ error: '只能删除自己的动态' });
    }
    /* 评论与通知为多态关联，无外键，删除动态时手动清理 */
    await prisma.comment.deleteMany({ where: { targetType: 'post', targetId: id } });
    await prisma.notification.deleteMany({ where: { targetType: 'post', targetId: id } });
    await prisma.post.delete({ where: { id } });
    await removeUploadedImages(parseImages(post.images));
    return { ok: true };
  });

  /** 用户主页：基础资料 + 动态数 / 获赞数，支持跨用户查看 */
  app.get('/users/:id', { preHandler: optionalAuth }, async (req, reply) => {
    const id = Number((req.params as any).id);
    const user = await prisma.user.findUnique({
      where: { id },
      select: { id: true, nickname: true, avatarIcon: true, role: true, createdAt: true },
    });
    if (!user) return reply.code(404).send({ error: '用户不存在' });

    const [postCount, postLikeSum, commentLikes] = await Promise.all([
      prisma.post.count({ where: { userId: id } }),
      prisma.post.aggregate({ where: { userId: id }, _sum: { likes: true } }),
      /* 获赞包含该用户收到的评论/回复点赞 */
      prisma.commentLike.count({ where: { comment: { userId: id } } }),
    ]);
    return {
      user,
      stats: {
        posts: postCount,
        likes: (postLikeSum._sum.likes ?? 0) + commentLikes,
      },
      isSelf: req.user?.id === id,
    };
  });
}
