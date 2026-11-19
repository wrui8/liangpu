import type { FastifyInstance } from 'fastify';
import { prisma } from '../db';
import { requireAuth } from '../auth';
import { serNotification } from '../serialize';

export async function notificationRoutes(app: FastifyInstance) {
  app.addHook('preHandler', requireAuth);

  /** 通知列表（最近的在前）+ 未读数；进入通知页时使用 */
  app.get('/notifications', async req => {
    const limit = Math.min(Math.max(Number((req.query as any).limit) || 50, 1), 100);
    const [rows, unread] = await Promise.all([
      prisma.notification.findMany({
        where: { userId: req.user.id },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: limit,
      }),
      prisma.notification.count({ where: { userId: req.user.id, read: false } }),
    ]);
    return { notifications: rows.map(serNotification), unread };
  });

  /** 只取未读数：客户端铃铛红点轮询，开销很小 */
  app.get('/notifications/unread', async req => {
    const count = await prisma.notification.count({
      where: { userId: req.user.id, read: false },
    });
    return { count };
  });

  /** 标记已读：带 id 只标记一条，不带则全部标记 */
  app.post('/notifications/read', async req => {
    const id = Number((req.body as any)?.id) || null;
    if (id) {
      await prisma.notification.updateMany({
        where: { id, userId: req.user.id },
        data: { read: true },
      });
    } else {
      await prisma.notification.updateMany({
        where: { userId: req.user.id, read: false },
        data: { read: true },
      });
    }
    return { ok: true };
  });
}
