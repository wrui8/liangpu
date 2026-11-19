# ---------- 管理后台构建 ----------
FROM node:20-bookworm-slim AS admin-build
WORKDIR /build/admin
RUN npm config set registry https://registry.npmmirror.com && npm config set fetch-retries 5
COPY admin/package*.json ./
RUN npm ci
COPY admin/ ./
RUN npm run build

# ---------- 后端构建 ----------
FROM node:20-bookworm-slim AS server-build
WORKDIR /build/server
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true; \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true; \
    apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN npm config set registry https://registry.npmmirror.com && npm config set fetch-retries 5
ENV DATABASE_URL=file:/tmp/build.db
ENV PRISMA_ENGINES_MIRROR=https://registry.npmmirror.com/-/binary/prisma
COPY server/package*.json ./
RUN npm ci
COPY server/ ./
RUN npx prisma generate && npm run build

# ---------- 运行镜像 ----------
FROM node:20-bookworm-slim
RUN sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || true; \
    sed -i 's|deb.debian.org|mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || true; \
    apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=server-build /build/server/node_modules ./server/node_modules
COPY --from=server-build /build/server/dist ./server/dist
COPY --from=server-build /build/server/prisma ./server/prisma
COPY --from=server-build /build/server/package.json ./server/package.json
COPY --from=admin-build  /build/admin/dist ./admin/dist
COPY docs/prototype ./docs/prototype
COPY docs/download ./docs/download
COPY docker-entrypoint.sh /app/docker-entrypoint.sh

RUN chmod +x /app/docker-entrypoint.sh && mkdir -p /app/data/uploads

ENV DATABASE_URL=file:/app/data/liangpu.db
ENV PORT=7001
ENV HOST=0.0.0.0
ENV TZ=Asia/Shanghai

EXPOSE 7001
WORKDIR /app/server
ENTRYPOINT ["/app/docker-entrypoint.sh"]
