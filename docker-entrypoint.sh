#!/bin/sh
set -e

mkdir -p /app/data /app/data/uploads

FIRST_RUN=
if [ ! -f /app/data/liangpu.db ]; then FIRST_RUN=1; fi

# 每次启动同步表结构（db push 为幂等操作，新增表 / 字段可直接升级旧库）
echo "同步数据库结构..."
npx prisma db push --skip-generate

if [ -n "$FIRST_RUN" ]; then
  echo "首次启动：写入演示数据..."
  node dist/seed.js
fi

# 团队分 = 团队直接评分 + 员工评分合并平均；每次启动校正历史数据
echo "重算团队合并评分..."
node dist/recalc-teams.js

# 需求总分 = 自身评分 70% + 需求内成员表现分 30%；没有评分时保持原展示分
echo "重算需求总分..."
node dist/recalc-needs.js

# 老评论只有 parentId：回填 rootId / replyToUserId，支持多层级回复
echo "回填评论层级..."
node dist/backfill-comments.js

exec node dist/index.js
