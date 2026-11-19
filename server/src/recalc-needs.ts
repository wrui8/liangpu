import './env';
import { prisma } from './db';
import { recalcNeedScore } from './needScore';

/**
 * 重算需求总分：自身评分 70% + 需求内成员表现分 30%（权重可由 NEED_SELF_WEIGHT 配置）。
 * 启动时执行一次，用于历史数据校正；完全没有评分的需求保持演示展示分。
 */
async function main() {
  const needs = await prisma.need.findMany({ select: { id: true } });
  let updated = 0;
  for (const n of needs) {
    if (await recalcNeedScore(prisma, n.id)) updated += 1;
  }
  console.log(`  需求总分重算完成：${updated}/${needs.length}`);
  await prisma.$disconnect();
}

main().catch(async err => {
  console.error('需求总分重算失败', err);
  await prisma.$disconnect();
  process.exit(1);
});
