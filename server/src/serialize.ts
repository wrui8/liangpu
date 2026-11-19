import { parseDist, distPercent, parseTags, round1 } from './utils';

export function serTeam(t: any) {
  return {
    id: t.id,
    name: t.name,
    category: t.category,
    short: t.short,
    iconKey: t.iconKey,
    color1: t.color1,
    color2: t.color2,
    score: round1(t.score),
    count: t.ratingCount,
    dist: distPercent(parseDist(t.dist)),
    tags: parseTags(t.tags),
    sort: t.sort,
  };
}

export function serEmployee(e: any) {
  return {
    id: e.id,
    teamId: e.teamId,
    name: e.name,
    title: e.title,
    iconKey: e.iconKey || null,
    short: e.name.slice(0, 1),
    color1: e.color1,
    color2: e.color2,
    score: round1(e.score),
    count: e.ratingCount,
    dist: distPercent(parseDist(e.dist)),
    sort: e.sort,
  };
}

export function serNeed(n: any) {
  return {
    id: n.id,
    title: n.title,
    desc: n.desc,
    category: n.category,
    status: n.status,
    teamId: n.teamId,
    teamName: n.team ? n.team.name : null,
    proposerName: n.proposerName,
    proposerId: n.proposerId ?? null,
    images: parseImages(n.images),
    score: round1(n.score),
    count: n.voteCount,
    dist: distPercent(parseDist(n.dist)),
    tags: parseTags(n.tags),
    createdAt: n.createdAt,
    sort: n.sort,
  };
}

export function serUserBrief(u: any) {
  if (!u) return null;
  return {
    id: u.id,
    nickname: u.nickname,
    avatarIcon: u.avatarIcon,
    role: u.role,
  };
}

export function parseImages(raw: any): string[] {
  if (typeof raw !== 'string' || !raw) return [];
  try {
    const v = JSON.parse(raw);
    return Array.isArray(v) ? v.filter(x => typeof x === 'string') : [];
  } catch {
    return [];
  }
}

/** 评论序列化：点赞态来自 c.likesBy；replyToName 用于「回复 @某人」 */
export function serComment(c: any, replyToName: string | null = null): any {
  const liked = Array.isArray(c.likesBy) ? c.likesBy.length > 0 : false;
  const replies = Array.isArray(c.replies) ? c.replies : [];
  return {
    id: c.id,
    userId: c.userId,
    user: c.user ? c.user.nickname : '',
    avatarIcon: c.user ? c.user.avatarIcon : 'u1',
    score: c.score,
    text: c.content,
    likes: c.likes,
    liked,
    parentId: c.parentId ?? null,
    rootId: c.rootId ?? null,
    replyToUserId: c.replyToUserId ?? null,
    replyToName: replyToName ?? c.replyToName ?? null,
    createdAt: c.createdAt,
    replyCount: typeof c._count?.replies === 'number' ? c._count.replies : replies.length,
    replies: replies.map((r: any) => serComment(r)),
  };
}

/**
 * 加载亮评：根评论 + 全部后代回复。
 * 回复在存储上保留真实父子层级，返回时按根评论扁平化（按时间排序），
 * 每条带上被回复人昵称，客户端显示「A 回复 B」。
 * 内网评论量小，按目标一次取 1000 条足够。
 */
export async function loadComments(
  db: any,
  targetType: string,
  targetId: number,
  myId?: number,
  scopeType = '',
  scopeId = 0,
) {
  const likeSel = myId ? { where: { userId: myId }, select: { id: true } } : undefined;
  const rows: any[] = await db.comment.findMany({
    where: { targetType, targetId, scopeType, scopeId },
    include: {
      user: true,
      ...(likeSel ? { likesBy: likeSel } : {}),
      _count: { select: { replies: true } },
    },
    orderBy: { id: 'asc' },
    take: 1000,
  });
  const byId = new Map<number, any>(rows.map(c => [c.id, c]));

  /* 根评论：优先用 rootId；旧数据沿 parentId 回溯（最多 64 层防环） */
  const rootOf = (c: any): number => {
    let cur = c;
    let guard = 0;
    while (cur.parentId != null && guard++ < 64) {
      if (cur.rootId) return cur.rootId;
      const p = byId.get(cur.parentId);
      if (!p) return cur.parentId;
      cur = p;
    }
    return cur.id;
  };

  const groups = new Map<number, any[]>();
  for (const c of rows) {
    if (c.parentId == null) continue;
    const rid = rootOf(c);
    if (!groups.has(rid)) groups.set(rid, []);
    groups.get(rid)!.push(c);
  }

  return rows
    .filter(c => c.parentId == null)
    .map(root => {
      const list = groups.get(root.id) ?? [];
      return {
        ...serComment(root),
        replyCount: list.length,
        replies: list.map(r => {
          const parent = byId.get(r.parentId);
          return serComment(
            { ...r, replyToUserId: r.replyToUserId ?? parent?.userId ?? null },
            parent?.user?.nickname ?? null,
          );
        }),
      };
    });
}

export function serPost(p: any, commentCount = 0) {
  const liked = Array.isArray(p.likesBy) ? p.likesBy.length > 0 : false;
  return {
    id: p.id,
    content: p.content,
    images: parseImages(p.images),
    likes: p.likes,
    liked,
    commentCount,
    createdAt: p.createdAt,
    user: serUserBrief(p.user),
  };
}

/** 通知序列化：actor 使用触发时的昵称 / 头像快照 */
export function serNotification(n: any) {
  return {
    id: n.id,
    type: n.type,
    targetType: n.targetType,
    targetId: n.targetId,
    commentId: n.commentId ?? null,
    preview: n.preview,
    read: n.read,
    createdAt: n.createdAt,
    actor: {
      id: n.actorId,
      nickname: n.actorName,
      avatarIcon: n.actorIcon,
    },
  };
}
