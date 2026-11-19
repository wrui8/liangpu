import fs from 'fs';
import fsp from 'fs/promises';
import path from 'path';
import crypto from 'crypto';

/** 动态配图存放目录：默认 <项目>/data/uploads，容器内即 /app/data/uploads（已随 docker-data 持久化） */
export const uploadsDir = process.env.UPLOAD_DIR || path.resolve(__dirname, '..', '..', 'data', 'uploads');
export const uploadsPrefix = '/uploads/';
export const MAX_IMAGE_BYTES = 4 * 1024 * 1024;

const EXT_BY_MIME: Record<string, string> = {
  jpeg: 'jpg',
  jpg: 'jpg',
  png: 'png',
  webp: 'webp',
  gif: 'gif',
};

export function ensureUploadsDir() {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

function sniffExtension(buf: Buffer, mimeExt: string): string | null {
  if (buf.length >= 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff) return 'jpg';
  if (buf.length >= 8 && buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47) return 'png';
  if (buf.length >= 6 && buf.subarray(0, 4).toString('ascii') === 'GIF8') return 'gif';
  if (
    buf.length >= 12 &&
    buf.subarray(0, 4).toString('ascii') === 'RIFF' &&
    buf.subarray(8, 12).toString('ascii') === 'WEBP'
  ) {
    return 'webp';
  }
  return EXT_BY_MIME[mimeExt] ?? null;
}

/**
 * 接收 data URL（data:image/jpeg;base64,...），校验大小与文件头后落盘。
 * 返回可访问的相对地址 /uploads/<name>，失败抛出带中文说明的 Error。
 */
export async function saveImageDataUrl(dataUrl: string): Promise<string> {
  const m = /^data:image\/([a-zA-Z0-9.+-]+);base64,([A-Za-z0-9+/=\s]+)$/.exec(dataUrl.trim());
  if (!m) throw new Error('图片格式不正确，请上传 JPG / PNG / WEBP / GIF');
  const mimeExt = m[1].toLowerCase().replace('jpg', 'jpeg');
  if (!EXT_BY_MIME[mimeExt]) throw new Error('仅支持 JPG / PNG / WEBP / GIF 图片');
  const buf = Buffer.from(m[2].replace(/\s+/g, ''), 'base64');
  if (!buf.length) throw new Error('图片内容为空');
  if (buf.length > MAX_IMAGE_BYTES) throw new Error('单张图片不能超过 4MB');
  const ext = sniffExtension(buf, mimeExt);
  if (!ext) throw new Error('图片内容无法识别');

  ensureUploadsDir();
  const name = `${Date.now().toString(36)}${crypto.randomBytes(8).toString('hex')}.${ext}`;
  await fsp.writeFile(path.join(uploadsDir, name), buf);
  return `${uploadsPrefix}${name}`;
}

/** 删除动态时清理其配图（只处理 /uploads/ 下的文件） */
export async function removeUploadedImages(images: string[]) {
  for (const img of images) {
    if (typeof img !== 'string' || !img.startsWith(uploadsPrefix)) continue;
    const name = path.basename(img);
    if (!name || name.includes('..')) continue;
    await fsp.unlink(path.join(uploadsDir, name)).catch(() => undefined);
  }
}
