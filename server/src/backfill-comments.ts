import './env';
import { prisma } from './db';

/**
 * 评论层级回填：老数据只有 parentId，没有 rootId / replyToUserId。
 * 启动时补全，保证多层级回复查询与「回复 @某人」显示完整；幂等。
 */
async function main() {
  const rows = await prisma.comment.findMany({
    select: { id: true, parentId: true, userId: true, rootId: true, replyToUserId: true },
  });
  const byId = new Map(rows.map(c => [c.id, c]));
  let updated = 0;

  for (const c of rows) {
    if (c.parentId == null) continue;
    const data: any = {};
    if (c.replyToUserId == null) {
      const parent = byId.get(c.parentId);
      if (parent) data.replyToUserId = parent.userId;
    }
    if (c.rootId == null) {
      let cur = c;
      let guard = 0;
      while (cur.parentId != null && guard++ < 64) {
        const parent = byId.get(cur.parentId);
        if (!parent) break;
        cur = parent;
      }
      if (cur.id !== c.id) data.rootId = cur.id;
    }
    if (Object.keys(data).length) {
      await prisma.comment.update({ where: { id: c.id }, data });
      updated += 1;
    }
  }

  console.log(`  评论层级回填完成：${updated} 条`);
  await prisma.$disconnect();
}

main().catch(async err => {
  console.error('评论层级回填失败', err);
  await prisma.$disconnect();
  process.exit(1);
});
