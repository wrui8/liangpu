// 生成小狮子 SVG（与 Flutter 端 lion_art.dart 同参数），
// 输出 design/lion.svg、admin/public/lion.svg 以及可内联到预览页的 symbol 片段。
import { writeFileSync } from 'node:fs';

const N = 12;
const step = (Math.PI * 2) / N;
const deg = (a) => (a * 180) / Math.PI;

function petals(back) {
  const out = [];
  for (let i = 0; i < N; i++) {
    const a = i * step + (back ? 0 : step / 2);
    const rx = back ? 10.5 : 7.6;
    const ry = back ? 17.5 : 13.2;
    const radius = back ? 27 : 26;
    const cx = 50 + Math.cos(a) * radius;
    const cy = 52 + Math.sin(a) * radius;
    const rot = deg(a) + 90;
    const grad = back ? 'url(#maneBack)' : 'url(#maneFront)';
    const rootGrad = back ? 'url(#maneRootBack)' : 'url(#maneRootFront)';
    const tipLight = back ? 'url(#petalLightBack)' : 'url(#petalLightFront)';
    out.push(`    <g transform="translate(${cx.toFixed(2)} ${cy.toFixed(2)}) rotate(${rot.toFixed(2)})">
      <ellipse rx="${rx}" ry="${ry}" fill="${grad}"/>
      <ellipse cx="0" cy="${(-ry * 0.34).toFixed(2)}" rx="${(rx * 0.675).toFixed(2)}" ry="${(ry * 0.525).toFixed(2)}" fill="${tipLight}"/>
      <ellipse cx="0" cy="${(ry * 0.62).toFixed(2)}" rx="${(rx * 1.5).toFixed(2)}" ry="${(ry * 0.9).toFixed(2)}" fill="${rootGrad}"/>
    </g>`);
  }
  return out.join('\n');
}

function eye(dx, hidden) {
  return `    <g transform="translate(${(50 + dx).toFixed(2)} 49.4)"${hidden ? ' class="eye-group"' : ''}>
      <ellipse rx="4.7" ry="5.2" fill="url(#eyeGrad)"/>
      <circle cx="-1.7" cy="-1.5" r="1.9" fill="rgba(255,255,255,.92)"/>
      <circle cx="1.5" cy="1.6" r="0.85" fill="rgba(255,255,255,.55)"/>
    </g>`;
}

function body(withBlink) {
  const blinkL = withBlink
    ? `<animateTransform attributeName="transform" type="scale" values="1 1;1 1;1 1;1 0.08;1 0.08;1 1" keyTimes="0;0.84;0.855;0.869;0.88;0.92" dur="5.2s" repeatCount="indefinite"/>`
    : '';
  const blinkR = blinkL;

  return `  <!-- 投影 -->
  <ellipse cx="50" cy="91" rx="26" ry="5.5" fill="rgba(26,18,8,.20)" filter="url(#softBlur)"/>
  <!-- 后圈鬃毛 -->
${petals(true)}
  <!-- 前圈鬃毛 -->
${petals(false)}
  <!-- 耳朵（压在鬃毛上、脸之下） -->
  <ellipse cx="35" cy="32.5" rx="8.75" ry="8.75" fill="url(#earGrad)" stroke="rgba(217,130,26,.35)" stroke-width="1.2"/>
  <ellipse cx="65" cy="32.5" rx="8.75" ry="8.75" fill="url(#earGrad)" stroke="rgba(217,130,26,.35)" stroke-width="1.2"/>
  <ellipse cx="35" cy="33.3" rx="3" ry="3.5" fill="#B9722A"/>
  <ellipse cx="65" cy="33.3" rx="3" ry="3.5" fill="#B9722A"/>
  <!-- 脸（先垫一圈环境阴影，让头浮在鬃毛前） -->
  <circle cx="50" cy="54" r="20.8" fill="rgba(122,74,22,.22)" filter="url(#softBlur)"/>
  <circle cx="50" cy="52" r="21" fill="url(#faceGrad)"/>
  <circle cx="50" cy="52" r="21" fill="url(#faceEdgeShade)"/>
  <path d="M30.8 47.1 A19.8 19.8 0 0 1 66.0 40.4" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="1.6" stroke-linecap="round"/>
  <path d="M65.7 62.0 A18.6 18.6 0 0 1 40.0 67.7" fill="none" stroke="rgba(255,233,184,.45)" stroke-width="2.2" stroke-linecap="round"/>
  <!-- 口鼻 -->
  <ellipse cx="42.8" cy="63" rx="9" ry="7.5" fill="url(#muzzleGrad)"/>
  <ellipse cx="57.2" cy="63" rx="9" ry="7.5" fill="url(#muzzleGrad)"/>
  <!-- 腮红 -->
  <ellipse cx="37" cy="59.5" rx="5.5" ry="3.5" fill="url(#blushGrad)"/>
  <ellipse cx="63" cy="59.5" rx="5.5" ry="3.5" fill="url(#blushGrad)"/>
  <!-- 鼻子 -->
  <path d="M45.2 55.4 L54.8 55.4 Q56.2 55.4 55.5 56.8 L52.3 61.4 Q50 63.7 47.7 61.4 L44.5 56.8 Q43.8 55.4 45.2 55.4 Z" fill="url(#noseGrad)"/>
  <ellipse cx="48.6" cy="57.3" rx="1.8" ry="1.1" fill="rgba(255,255,255,.38)"/>
  <!-- 嘴 -->
  <path d="M50 61.6 L50 64.2 M50 64.2 Q46.6 67.4 44.2 65.2 M50 64.2 Q53.4 67.4 55.8 65.2" fill="none" stroke="#5C3823" stroke-width="1.7" stroke-linecap="round"/>
  <!-- 眼睛 -->
  <g transform="translate(41.4 49.4)">
    <g>${blinkL}
      <ellipse rx="4.7" ry="5.2" fill="url(#eyeGrad)"/>
      <circle cx="-1.7" cy="-1.5" r="1.9" fill="rgba(255,255,255,.92)"/>
      <circle cx="1.5" cy="1.6" r="0.85" fill="rgba(255,255,255,.55)"/>
    </g>
  </g>
  <g transform="translate(58.6 49.4)">
    <g>${blinkR}
      <ellipse rx="4.7" ry="5.2" fill="url(#eyeGrad)"/>
      <circle cx="-1.7" cy="-1.5" r="1.9" fill="rgba(255,255,255,.92)"/>
      <circle cx="1.5" cy="1.6" r="0.85" fill="rgba(255,255,255,.55)"/>
    </g>
  </g>`;
}

const defs = `  <defs>
    <filter id="softBlur" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="2.2"/>
    </filter>
    <linearGradient id="maneBack" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0" stop-color="#EFA025"/>
      <stop offset="1" stop-color="#C9760F"/>
    </linearGradient>
    <linearGradient id="maneFront" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0" stop-color="#FFCE4F"/>
      <stop offset="1" stop-color="#EFA025"/>
    </linearGradient>
    <radialGradient id="maneRootBack">
      <stop offset="0" stop-color="rgba(217,130,26,.55)"/>
      <stop offset="1" stop-color="rgba(217,130,26,0)"/>
    </radialGradient>
    <radialGradient id="maneRootFront">
      <stop offset="0" stop-color="rgba(239,160,37,.55)"/>
      <stop offset="1" stop-color="rgba(239,160,37,0)"/>
    </radialGradient>
    <radialGradient id="petalLightBack">
      <stop offset="0" stop-color="rgba(255,255,255,.16)"/>
      <stop offset="1" stop-color="rgba(255,255,255,0)"/>
    </radialGradient>
    <radialGradient id="petalLightFront">
      <stop offset="0" stop-color="rgba(255,255,255,.26)"/>
      <stop offset="1" stop-color="rgba(255,255,255,0)"/>
    </radialGradient>
    <radialGradient id="faceGrad" cx="0.5" cy="0.5" r="0.72" fx="0.32" fy="0.24">
      <stop offset="0" stop-color="#FFF3CE"/>
      <stop offset="0.58" stop-color="#FFD98A"/>
      <stop offset="1" stop-color="#E9A23B"/>
    </radialGradient>
    <radialGradient id="faceEdgeShade" cx="0.35" cy="0.3" r="0.85">
      <stop offset="0" stop-color="rgba(122,74,22,0)"/>
      <stop offset="0.72" stop-color="rgba(122,74,22,0)"/>
      <stop offset="1" stop-color="rgba(122,74,22,.26)"/>
    </radialGradient>
    <radialGradient id="blushGrad">
      <stop offset="0" stop-color="rgba(255,143,92,.40)"/>
      <stop offset="1" stop-color="rgba(255,143,92,0)"/>
    </radialGradient>
    <radialGradient id="earGrad" cx="0.5" cy="0.5" r="0.65" fx="0.35" fy="0.3">
      <stop offset="0" stop-color="#FFD98A"/>
      <stop offset="1" stop-color="#E7A03A"/>
    </radialGradient>
    <radialGradient id="muzzleGrad" cx="0.5" cy="0.5" r="0.7" fx="0.4" fy="0.25">
      <stop offset="0" stop-color="#FFF9EC"/>
      <stop offset="1" stop-color="#F1DCB8"/>
    </radialGradient>
    <linearGradient id="noseGrad" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0" stop-color="#7E4E32"/>
      <stop offset="1" stop-color="#4E2E1C"/>
    </linearGradient>
    <linearGradient id="eyeGrad" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0" stop-color="#463026"/>
      <stop offset="1" stop-color="#33221A"/>
    </linearGradient>
  </defs>`;

const svg = (withBlink) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="100%" height="100%">
${defs}
${body(withBlink)}
</svg>
`;

writeFileSync('lion.svg', svg(false));
writeFileSync('admin-lion.svg', svg(true));
console.log('written design/lion.svg, design/admin-lion.svg');
