// 把生成的 SVG 内联进预览页（file:// 下不能用 fetch，所以直接注入）
import { readFileSync, writeFileSync } from 'node:fs';

const svg = readFileSync(new URL('./admin-lion.svg', import.meta.url), 'utf8');
const tpl = readFileSync(new URL('./preview.template.html', import.meta.url), 'utf8');
const html = tpl.replace('{{LION_SVG}}', svg.trim());
writeFileSync(new URL('./preview.html', import.meta.url), html);
console.log('preview.html rebuilt,', html.length, 'bytes');
