// 清空所有用户评分与评论，并将团队 / 员工 / 需求的评分统计归零。
// 只删用户产生的内容，保留用户账号、团队、员工、需求、图标等基础数据。
//
// 用法（先停容器再执行，避免并发写入）：
//   cd /d D:\code\liangpu\server
//   DATABASE_URL=file:../../docker-data/liangpu.db node scripts/clear-user-feedback.js
const { PrismaClient } = require('@prisma/client')

const prisma = new PrismaClient()
const zeroDist = JSON.stringify(Array(10).fill(0))

async function main() {
  const before = {
    rating: await prisma.rating.count(),
    comment: await prisma.comment.count(),
    commentLike: await prisma.commentLike.count(),
  }

  await prisma.$transaction([
    prisma.commentLike.deleteMany(),
    prisma.comment.deleteMany(),
    prisma.rating.deleteMany(),
    prisma.team.updateMany({ data: { score: 0, ratingCount: 0, dist: zeroDist } }),
    prisma.employee.updateMany({ data: { score: 0, ratingCount: 0, dist: zeroDist } }),
    prisma.need.updateMany({ data: { score: 0, voteCount: 0, dist: zeroDist } }),
  ])

  console.log('已清空评分/评论:', before)
}

main()
  .catch((e) => {
    console.error(e)
    process.exitCode = 1
  })
  .finally(() => prisma.$disconnect())
