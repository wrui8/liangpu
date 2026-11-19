type Db = any;

export interface CombinedTeamScore {
  score: number;
  count: number;
  dist: number[];
}

/**
 * 团队合并评分：
 * 团队分 = 团队直接评分 + 该团队全部员工评分（仅全局维度）的算术平均（每条评分计一次）。
 * 需求内成员表现分（scopeType=need）不参与团队分。
 */
export async function computeTeamScore(db: Db, teamId: number): Promise<CombinedTeamScore> {
  const employees = await db.employee.findMany({ where: { teamId }, select: { id: true } });
  const employeeIds = employees.map((e: any) => e.id);

  const [teamRatings, employeeRatings] = await Promise.all([
    db.rating.findMany({
      where: { targetType: 'team', targetId: teamId, scopeType: '', scopeId: 0 },
      select: { score: true },
    }),
    employeeIds.length
      ? db.rating.findMany({
          where: {
            targetType: 'employee',
            targetId: { in: employeeIds },
            scopeType: '',
            scopeId: 0,
          },
          select: { score: true },
        })
      : Promise.resolve([] as Array<{ score: number }>),
  ]);

  const scores = [...teamRatings, ...employeeRatings]
    .map((r: any) => Number(r.score))
    .filter((s: number) => Number.isInteger(s) && s >= 1 && s <= 10);

  const dist = new Array(10).fill(0) as number[];
  let sum = 0;
  for (const s of scores) {
    dist[s - 1] += 1;
    sum += s;
  }
  const count = scores.length;
  return { score: count ? sum / count : 0, count, dist };
}

/**
 * 有真实评分时，把合并结果回写到 team 表（score / ratingCount / dist）；
 * 没有任何评分时保留原有展示分（种子演示数据），避免被清零。
 */
export async function recalcTeamScore(db: Db, teamId: number): Promise<CombinedTeamScore | null> {
  const result = await computeTeamScore(db, teamId);
  if (result.count === 0) return null;
  await db.team.update({
    where: { id: teamId },
    data: {
      score: result.score,
      ratingCount: result.count,
      dist: JSON.stringify(result.dist),
    },
  });
  return result;
}
