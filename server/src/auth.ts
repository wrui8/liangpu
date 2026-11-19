import type { FastifyReply, FastifyRequest } from 'fastify';

export interface JwtUser {
  id: number;
  username: string;
  nickname: string;
  role: string;
}

declare module '@fastify/jwt' {
  interface FastifyJWT {
    payload: JwtUser;
    user: JwtUser;
  }
}

export async function requireAuth(req: FastifyRequest, reply: FastifyReply) {
  try {
    await req.jwtVerify();
  } catch {
    return reply.code(401).send({ error: '请先登录' });
  }
}

export async function requireAdmin(req: FastifyRequest, reply: FastifyReply) {
  await requireAuth(req, reply);
  if ((req.user as JwtUser | undefined)?.role !== 'admin') {
    return reply.code(403).send({ error: '需要管理员权限' });
  }
}

/** 公开接口可选登录：带 token 时解析出当前用户，便于返回点赞状态。 */
export async function optionalAuth(req: FastifyRequest) {
  try {
    await req.jwtVerify();
  } catch {
    /* 匿名浏览 */
  }
}
