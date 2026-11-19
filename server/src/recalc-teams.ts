import './env';
import { prisma } from './db';
import { recalcTeamScore } from './teamScore';

/**
 * 把「团队直接评分 + 员工评分」合并重算到 team 表。
 * 启动时执行一次，用于历史数据校正；没有评分的团队保持演示展示分。
 */
async function main() {
  const teams = await prisma.team.findMany({ select: { id: true } });
  let updated = 0;
  for (const t of teams) {
    if (await recalcTeamScore(prisma, t.id)) updated += 1;
  }
  console.log(`  团队评分合并重算完成：${updated}/${teams.length}`);
  await prisma.$disconnect();
}

main().catch(async err => {
  console.error('团队评分重算失败', err);
  await prisma.$disconnect();
  process.exit(1);
});
