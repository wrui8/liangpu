import './env';
import os from 'os';
import fs from 'fs';
import net from 'net';
import path from 'path';
import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import fastifyStatic from '@fastify/static';
import { authRoutes } from './routes/auth';
import { catalogRoutes } from './routes/catalog';
import { ratingRoutes } from './routes/ratings';
import { postRoutes } from './routes/posts';
import { notificationRoutes } from './routes/notifications';
import { adminRoutes } from './routes/admin';
import { agentRoutes, adminAgentRoutes } from './routes/agent';
import { ensureUploadsDir, uploadsDir } from './uploads';

const tlsCert = process.env.TLS_CERT;
const tlsKey = process.env.TLS_KEY;
const useTls = Boolean(tlsCert && tlsKey);

const app = Fastify({
  logger: { level: 'info' },
  ...(useTls
    ? { https: { key: fs.readFileSync(tlsKey as string), cert: fs.readFileSync(tlsCert as string) } }
    : {}),
});
const scheme = useTls ? 'https' : 'http';

app.register(cors, { origin: true });
app.register(jwt, {
  secret: process.env.JWT_SECRET || 'liangpu-dev-secret',
  sign: { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
});

app.get('/api/health', async () => ({ ok: true, name: 'liangpu', time: new Date().toISOString() }));

app.register(authRoutes, { prefix: '/api' });
app.register(catalogRoutes, { prefix: '/api' });
app.register(ratingRoutes, { prefix: '/api' });
app.register(postRoutes, { prefix: '/api' });
app.register(notificationRoutes, { prefix: '/api' });
app.register(adminRoutes, { prefix: '/api/admin' });
app.register(agentRoutes, { prefix: '/api' });
app.register(adminAgentRoutes, { prefix: '/api/admin' });

/* 动态配图（与数据库同在 docker-data 下，随数据备份） */
ensureUploadsDir();
app.register(fastifyStatic, {
  root: uploadsDir,
  prefix: '/uploads/',
  decorateReply: false,
  maxAge: '7d',
});

/* 管理后台前端（构建产物存在时托管），单端口部署 */
const adminDist = path.resolve(__dirname, '..', '..', 'admin', 'dist');
if (fs.existsSync(adminDist)) {
  app.register(fastifyStatic, { root: adminDist, prefix: '/' });
  app.setNotFoundHandler((req, reply) => {
    if (req.method === 'GET' && !req.url.startsWith('/api') && !req.url.includes('.')) {
      return reply.type('text/html').send(fs.readFileSync(path.join(adminDist, 'index.html')));
    }
    return reply.code(404).send({ error: 'Not Found' });
  });
}

/* UI 原型，方便内网直接预览 */
const protoDir = path.resolve(__dirname, '..', '..', 'docs', 'prototype');
if (fs.existsSync(protoDir)) {
  app.register(fastifyStatic, { root: protoDir, prefix: '/prototype/', decorateReply: false, index: ['index.html'] });
}

/* 官网与客户端下载页 */
const siteDir = path.resolve(__dirname, '..', '..', 'docs', 'download');
if (fs.existsSync(siteDir)) {
  app.register(fastifyStatic, { root: siteDir, prefix: '/download/', decorateReply: false, index: ['index.html'] });
}

/* 客户端安装包（宿主机 docker-data/downloads 只读挂载） */
const downloadsDir = process.env.DOWNLOAD_DIR || path.resolve(__dirname, '..', '..', 'downloads');
if (fs.existsSync(downloadsDir)) {
  app.register(fastifyStatic, { root: downloadsDir, prefix: '/downloads/', decorateReply: false });
}

const port = Number(process.env.PORT || 7001);
const host = process.env.HOST || '0.0.0.0';

/* ===== 官网公开站点（独立明文端口） =====
   下载页面向所有人（包括没装内部 CA 的手机浏览器），不能挂在需要信任内部证书的 7001。
   该端口只托管官网页面与安装包，不暴露任何 API 或管理端。 */
/* 注意：TLS 模式下主服务的内部端口默认是 PORT+1（7002），公开端口需避开 */
const publicPort = Number(process.env.PUBLIC_PORT || 7003);
const publicHost = process.env.PUBLIC_HOST || '0.0.0.0';

function startPublicSite() {
  const publicApp = Fastify({ logger: { level: 'info' } });

  if (fs.existsSync(siteDir)) {
    publicApp.register(fastifyStatic, {
      root: siteDir,
      prefix: '/download/',
      index: ['index.html'],
    });
  }
  if (fs.existsSync(downloadsDir)) {
    publicApp.register(fastifyStatic, {
      root: downloadsDir,
      prefix: '/downloads/',
      decorateReply: false,
    });
  }
  publicApp.get('/', async (_req, reply) => reply.redirect('/download/'));
  publicApp.get('/download', async (_req, reply) => reply.redirect('/download/'));

  publicApp
    .listen({ port: publicPort, host: publicHost })
    .then(() => {
      console.log(`  官网下载   http://localhost:${publicPort}/download/  （明文，无需证书）`);
    })
    .catch(err => {
      app.log.error({ err }, `官网公开端口 ${publicPort} 监听失败`);
    });
}

startPublicSite();
/* HTTPS 模式下 Fastify 监听内部端口，外部端口由下面的 TCP 前置接管：
   浏览器误用 http:// 访问时返回 301 跳转到 https://，TLS 流量原样透传。 */
const listenPort = useTls ? Number(process.env.INTERNAL_PORT || port + 1) : port;
const listenHost = useTls ? '127.0.0.1' : host;

/**
 * 同端口 TLS 嗅探前置：
 * - 首字节为 TLS 握手（0x16 / 0x80）→ 原样转发到内部 HTTPS 端口；
 * - 否则按明文 HTTP 解析，返回 308 跳转到 https://<同一主机><路径>。
 * 这样用户直接输入「IP:7001」也能自动进入管理端，无需手动补 https://。
 */
function startTlsSniffer(externalPort: number, listenAddr: string) {
  const server = net.createServer(client => {
    let buf = Buffer.alloc(0);
    let decided = false;

    const onData = (chunk: Buffer) => {
      if (decided) return;
      buf = Buffer.concat([buf, chunk]);
      if (!buf.length) return;

      if (buf[0] === 0x16 || buf[0] === 0x80) {
        decided = true;
        client.removeListener('data', onData);
        client.pause();
        client.setTimeout(0);
        const upstream = net.connect(listenPort, '127.0.0.1');
        upstream.once('connect', () => {
          upstream.write(buf);
          client.pipe(upstream);
          upstream.pipe(client);
        });
        upstream.on('error', () => client.destroy());
        client.on('error', () => upstream.destroy());
        return;
      }

      const headerEnd = buf.indexOf('\r\n\r\n');
      if (headerEnd < 0 && buf.length < 16384) return;
      decided = true;
      client.removeListener('data', onData);

      const text = buf.toString('latin1', 0, headerEnd >= 0 ? headerEnd : buf.length);
      const lines = text.split('\r\n');
      const reqLine = /^[A-Z]+\s+(\S+)\s+HTTP\/\d\.\d$/.exec(lines[0] || '');
      const hostLine = lines.find(l => /^host:/i.test(l));
      const localAddr = client.localAddress || '';
      const fallbackHost = localAddr.includes(':') ? `[${localAddr}]:${externalPort}` : `${localAddr}:${externalPort}`;
      const targetHost = hostLine ? hostLine.slice(hostLine.indexOf(':') + 1).trim() : fallbackHost;
      let targetPath = reqLine ? reqLine[1] : '/';
      if (!targetPath.startsWith('/')) targetPath = '/';

      client.end(
        'HTTP/1.1 308 Permanent Redirect\r\n' +
          `Location: https://${targetHost}${targetPath}\r\n` +
          'Connection: close\r\nContent-Length: 0\r\n\r\n',
      );
    };

    client.on('data', onData);
    client.on('error', () => {});
    client.setTimeout(15000, () => client.destroy());
  });

  server.on('error', err => app.log.error({ err }, 'HTTP→HTTPS 前置监听失败'));
  server.listen(externalPort, listenAddr, () => {
    app.log.info(`HTTP→HTTPS 跳转已启用（${listenAddr}:${externalPort}）`);
  });
}

if (useTls) startTlsSniffer(port, host);

app
  .listen({ port: listenPort, host: listenHost })
  .then(() => {
    console.log('');
    console.log('  良扑服务已启动');
    console.log(`  本机访问   ${scheme}://localhost:${port}`);
    for (const list of Object.values(os.networkInterfaces())) {
      for (const ni of list || []) {
        if (ni.family === 'IPv4' && !ni.internal) {
          console.log(`  内网访问   ${scheme}://${ni.address}:${port}`);
        }
      }
    }
    console.log(`  管理后台   ${scheme}://localhost:${port}/`);
    console.log(`  UI 原型    ${scheme}://localhost:${port}/prototype/`);
    console.log(`  下载页     ${scheme}://localhost:${port}/download/`);
    console.log('');
  })
  .catch(err => {
    app.log.error(err);
    process.exit(1);
  });
