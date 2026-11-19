import { prisma } from './db';

export type NotifyType =
  | 'like_comment'
  | 'reply_comment'
  | 'like_post'
  | 'comment_post';

interface NotifyInput {
  userId: number; // 接收者
  actorId: number; // 触发者
  type: NotifyType;
  targetType: string; // team | employee | need | post
  targetId: number;
  commentId?: number | null;
  preview?: string;
}

/**
 * 写入一条通知。
 * - 自己操作自己的内容不通知；
 * - 通知失败只记日志，不影响点赞 / 回复 / 评论等主流程。
 */
export async function notify(input: NotifyInput): Promise<void> {
  if (!input.userId || input.userId === input.actorId) return;
  try {
    const actor = await prisma.user.findUnique({
      where: { id: input.actorId },
      select: { nickname: true, avatarIcon: true },
    });
    if (!actor) return;
    await prisma.notification.create({
      data: {
        userId: input.userId,
        actorId: input.actorId,
        actorName: actor.nickname,
        actorIcon: actor.avatarIcon,
        type: input.type,
        targetType: input.targetType,
        targetId: input.targetId,
        commentId: input.commentId ?? null,
        preview: String(input.preview ?? '').slice(0, 80),
      },
    });
  } catch (e) {
    console.error('写入通知失败', e);
  }
}
