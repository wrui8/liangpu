type Db = any;

export interface NeedScoreResult {
  /** 需求总分（自身分与成员分加权） */
  score: number;
  /** 需求自身评分（scope 为空） */
  selfScore: number;
  selfCount: number;
  /** 成员表现分：各成员在该需求下平均分的再平均（每成员等权） */
  memberScore: number;
  memberCount: number;
  /** 需求自身评分的 1-10 分布 */
  dist: number[];
}

/**
 * 需求自身评分权重（0~1），成员表现分权重为 1 - 该值。
 * 内网部署可通过 NEED_SELF_WEIGHT 调整，默认 70% / 30%。
 */
function selfWeight(): number {
  const raw = Number(process.env.NEED_SELF_WEIGHT);
  if (!Number.isFinite(raw) || raw < 0 || raw > 1) return 0.7;
  return raw;
}

function validScore(n: unknown): boolean {
  const s = Number(n);
  return Number.isInteger(s) && s >= 1 && s <= 10;
}

/**
 * 需求评分隔离规则：
 * - 需求自身评分（targetType=need，scope 为空）决定「需求总分」的主体；
 * - 需求内给成员打分（targetType=employee，scopeType=need，scopeId=需求 id）
 *   只属于该需求，不写入员工全局分、不参与团队分；
 * - 每个成员的需求平均分先算出来，再对所有成员等权平均；
 * - 只有一侧有评分时直接取该侧，避免另一侧 0 分把总分稀释。
 */
export async function computeNeedScore(db: Db, needId: number): Promise<NeedScoreResult> {
  const [selfRatings, memberRatings, members] = await Promise.all([
    db.rating.findMany({
      where: { targetType: 'need', targetId: needId, scopeType: '', scopeId: 0 },
      select: { score: true },
    }),
    db.rating.findMany({
      where: { targetType: 'employee', scopeType: 'need', scopeId: needId },
      select: { targetId: true, score: true },
    }),
    db.needMember.findMany({ where: { needId }, select: { employeeId: true } }),
  ]);

  const dist = new Array(10).fill(0) as number[];
  let selfSum = 0;
  for (const r of selfRatings) {
    if (!validScore(r.score)) continue;
    dist[Number(r.score) - 1] += 1;
    selfSum += Number(r.score);
  }
  const selfCount = dist.reduce((a, b) => a + b, 0);
  const selfScore = selfCount ? selfSum / selfCount : 0;

  /* 仅统计当前仍在该需求中的成员，避免移除成员后残留评分继续影响总分 */
  const memberIds = new Set<number>(members.map((m: any) => m.employeeId));
  const byMember = new Map<number, { sum: number; count: number }>();
  for (const r of memberRatings) {
    if (!memberIds.has(r.targetId) || !validScore(r.score)) continue;
    const cur = byMember.get(r.targetId) ?? { sum: 0, count: 0 };
    cur.sum += Number(r.score);
    cur.count += 1;
    byMember.set(r.targetId, cur);
  }
  let memberSum = 0;
  for (const v of byMember.values()) memberSum += v.sum / v.count;
  const memberCount = byMember.size;
  const memberScore = memberCount ? memberSum / memberCount : 0;

  let score = 0;
  if (selfCount && memberCount) {
    const w = selfWeight();
    score = selfScore * w + memberScore * (1 - w);
  } else if (selfCount) {
    score = selfScore;
  } else if (memberCount) {
    score = memberScore;
  }

  return { score, selfScore, selfCount, memberScore, memberCount, dist };
}

/**
 * 重算并回写需求总分。完全没有评分时保留原有展示分（种子演示数据），
 * 返回 null 表示未回写。
 */
export async function recalcNeedScore(db: Db, needId: number): Promise<NeedScoreResult | null> {
  const result = await computeNeedScore(db, needId);
  if (result.selfCount === 0 && result.memberCount === 0) return null;
  await db.need.update({
    where: { id: needId },
    data: {
      score: result.score,
      voteCount: result.selfCount,
      dist: JSON.stringify(result.dist),
    },
  });
  return result;
}

/** 清理某需求下全部成员维度的评分与短评（删除需求、移除成员时使用） */
export async function purgeNeedScopedRatings(db: Db, needId: number, employeeIds?: number[]) {
  const where: any = {
    targetType: 'employee',
    scopeType: 'need',
    scopeId: needId,
    ...(employeeIds ? { targetId: { in: employeeIds } } : {}),
  };
  await db.rating.deleteMany({ where });
  await db.comment.deleteMany({ where });
}
