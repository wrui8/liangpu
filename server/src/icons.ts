export type IconKind = 'team' | 'employee' | 'user';

export interface IconSeed {
  key: string;
  kind: IconKind;
  name: string;
  svg: string;
  sort: number;
}

const s = (inner: string) =>
  `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">${inner}</svg>`;

/* ---------- 团队图标 ---------- */
const TEAM_ICONS: Array<[string, string, string]> = [
  ['crown', '皇冠', '<path d="M4 17.5 3 8l5 3.8L12 5l4 6.8L21 8l-1 9.5z"/><path d="M4 20h16"/>'],
  ['wrench', '扳手', '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>'],
  ['box', '盒子', '<path d="m12 3 8 4.5v9L12 21l-8-4.5v-9L12 3z"/><path d="M4 7.5 12 12l8-4.5"/><path d="M12 12v9"/>'],
  ['users', '人群', '<circle cx="9" cy="8.5" r="3.2"/><path d="M3.5 20c0-3 2.4-5 5.5-5s5.5 2 5.5 5"/><circle cx="17" cy="9.5" r="2.3"/><path d="M16 20c.2-2.3 1.6-3.8 3.9-3.8.6 0 1.2.1 1.7.3"/>'],
  ['shield', '盾牌', '<path d="M12 3 5 6v6c0 4.4 3 7.4 7 9 4-1.6 7-4.6 7-9V6l-7-3z"/><path d="m9 12 2 2 4-4"/>'],
  ['chip', '芯片', '<rect x="7" y="7" width="10" height="10" rx="2"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5.5 5.5 7 7M17 17l1.5 1.5M18.5 5.5 17 7M7 17l-1.5 1.5"/>'],
  ['flask', '试管', '<path d="M9 3h6"/><path d="M10 3v6.4L5.8 17a2.4 2.4 0 0 0 2.1 3.4h8.2a2.4 2.4 0 0 0 2.1-3.4L14 9.4V3"/><path d="M7.5 15h9"/>'],
  ['code', '代码', '<path d="m8.5 8.5-4 3.5 4 3.5"/><path d="m15.5 8.5 4 3.5-4 3.5"/><path d="M13.5 5 10.5 19"/>'],
  ['layers', '层叠', '<path d="m12 3 9 5-9 5-9-5 9-5z"/><path d="m3 13 9 5 9-5"/>'],
  ['bolt', '闪电', '<path d="M13 2 4.5 13.5H11L9.5 22 19 10.5h-6.5L13 2z"/>'],
  ['database', '数据库', '<ellipse cx="12" cy="5.5" rx="8" ry="3"/><path d="M4 5.5v13c0 1.66 3.58 3 8 3s8-1.34 8-3v-13"/><path d="M20 11.5c0 1.66-3.58 3-8 3s-8-1.34-8-3"/>'],
  ['wind', '风', '<path d="M17.7 7.7a2.5 2.5 0 1 1 1.8 4.3H2"/><path d="M9.6 4.6A2 2 0 1 1 11 8H2"/><path d="M12.6 19.4A2 2 0 1 0 14 16H2"/>'],
  ['rocket', '火箭', '<path d="M4.5 16.5c-1.5 1.3-2 5-2 5s3.7-.5 5-2c.7-.8.7-2-.1-2.8-.8-.8-2.1-.9-2.9-.2z"/><path d="m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/><path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/>'],
  ['palette', '调色', '<circle cx="13.5" cy="6.5" r="1"/><circle cx="17.5" cy="10.5" r="1"/><circle cx="8.5" cy="7.5" r="1"/><circle cx="6.5" cy="12.5" r="1"/><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.93 0 1.65-.75 1.65-1.69 0-.44-.18-.84-.44-1.13-.29-.29-.44-.65-.44-1.13a1.66 1.66 0 0 1 1.69-1.69H16c3.31 0 6-2.69 6-6 0-4.96-4.49-8.36-10-8.36z"/>'],
  ['bulb', '灵感', '<path d="M9 18h6"/><path d="M10 22h4"/><path d="M12 2a7 7 0 0 0-4 12.7c.64.48 1 1.2 1 2V18h6v-1.3c0-.8.36-1.52 1-2A7 7 0 0 0 12 2z"/>'],
  ['gear', '齿轮', '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>'],
  ['book', '书本', '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>'],
  ['globe', '地球', '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a15 15 0 0 1 0 18 15 15 0 0 1 0-18z"/>'],
  ['chart', '图表', '<path d="M3 3v18h18"/><path d="M7 15v-4M12 15V7M17 15v-6"/>'],
  ['target', '靶心', '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1"/>'],
  ['puzzle', '拼图', '<path d="M19.4 14.5a2 2 0 0 0 .6-1.4 1.9 1.9 0 0 0-3.8 0 2 2 0 0 0 .6 1.4h-2.3v2.3a2 2 0 0 1-1.4-.6 1.9 1.9 0 0 0 0 3.8 2 2 0 0 1 1.4-.6v2.6H4V12h2.6a2 2 0 0 1-.6 1.4 1.9 1.9 0 0 0 0 3.8 2 2 0 0 0 1.4-.6 2 2 0 0 0 0-2.8 2 2 0 0 0-1.4-.6H4V4h9v2.6a2 2 0 0 1 1.4-.6 1.9 1.9 0 0 0 0-3.8 2 2 0 0 1-1.4.6V2h6.9v9h-.5z"/>'],
  ['coffee', '咖啡', '<path d="M17 8h1a4 4 0 1 1 0 8h-1"/><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4z"/><path d="M6 2v2M10 2v2M14 2v2"/>'],
];

/* ---------- 员工图标（管理端分配给员工） ---------- */
const EMPLOYEE_ICONS: Array<[string, string, string]> = [
  ['star', '星标', '<path d="m12 2.5 3 6.1 6.7 1-4.9 4.7 1.2 6.7-6-3.2-6 3.2 1.2-6.7L2.3 9.6l6.7-1 3-6.1z"/>'],
  ['medal', '奖章', '<circle cx="12" cy="9" r="5.5"/><path d="m8.5 13.5-2 8 5.5-3 5.5 3-2-8"/>'],
  ['bug', '捉虫', '<rect x="8" y="7" width="8" height="12" rx="4"/><path d="M9 7V5a3 3 0 0 1 6 0v2M8 11H4M20 11h-4M8 15H5M19 15h-3M12 19v3M8.5 5.5 6.5 3.5M15.5 5.5 17.5 3.5"/>'],
  ['terminal', '终端', '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="m7 9 3 3-3 3M13 15h4"/>'],
  ['pen', '画笔', '<path d="M12 19l7-7 3 3-7 7-3-3z"/><path d="M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z"/><path d="M2 2l7.586 7.586"/><circle cx="11" cy="11" r="2"/>'],
  ['headset', '客服', '<path d="M3 14v-2a9 9 0 0 1 18 0v2"/><path d="M3 14a2 2 0 0 1 2-2h1v6H5a2 2 0 0 1-2-2zM21 14a2 2 0 0 0-2-2h-1v6h1a2 2 0 0 0 2-2z"/><path d="M18 18v2a2 2 0 0 1-2 2h-3"/>'],
  ['hammer', '工具', '<path d="m14 6-4 4M3 21l7.5-7.5"/><path d="m13 2 3 3"/><path d="m16 5 3-3 4 4-3 3-2-2-2 2-3-3 3-1z"/>'],
  ['laptop', '开发', '<rect x="4" y="5" width="16" height="11" rx="2"/><path d="M2 20h20"/>'],
  ['compass', '统筹', '<circle cx="12" cy="12" r="9"/><path d="m16 8-2.5 6.5L8 16l2.5-6.5L16 8z"/>'],
  ['flame', '火力', '<path d="M12 2s5 5 5 10a5 5 0 0 1-10 0c0-2 1-3.5 2-4.5 0 2 1 3 2 3 0-3-1-5 .5-8.5z"/>'],
  ['eye', '洞察', '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/>'],
  ['gem', '精英', '<path d="M6 3h12l4 6-10 12L2 9l4-6z"/><path d="M2 9h20M12 21 8 9l4-6 4 6-4 12z"/>'],
];

/* ---------- 用户头���池（动画人像，用户可自选） ---------- */
interface AvatarSpec {
  key: string;
  name: string;
  bg: string;
  skin: string;
  hair: string;
  cloth: string;
  style: 'short' | 'long' | 'curly' | 'bun' | 'cap' | 'headphone' | 'glasses' | 'beard' | 'twintail' | 'buzz' | 'fringe' | 'band';
}

const AVATAR_SPECS: AvatarSpec[] = [
  { key: 'u1', name: '短发蓝', bg: '#EEF1FF', skin: '#FFD9B8', hair: '#3B2E2A', cloth: '#5B6CFF', style: 'short' },
  { key: 'u2', name: '长发粉', bg: '#FFEEF3', skin: '#FFE0C4', hair: '#2B211D', cloth: '#F06FA0', style: 'long' },
  { key: 'u3', name: '卷发绿', bg: '#EAFBF3', skin: '#F7C79B', hair: '#6B4423', cloth: '#2BC48A', style: 'curly' },
  { key: 'u4', name: '眼镜灰', bg: '#F0F2F5', skin: '#F2C89E', hair: '#2F2B28', cloth: '#6B7787', style: 'glasses' },
  { key: 'u5', name: '帽子橙', bg: '#FFF4E6', skin: '#FFD9B8', hair: '#E86A2B', cloth: '#FF8A3D', style: 'cap' },
  { key: 'u6', name: '双马尾紫', bg: '#F5F0FF', skin: '#FFDEC6', hair: '#5B3A29', cloth: '#8E4DFF', style: 'twintail' },
  { key: 'u7', name: '寸头黄', bg: '#FFFBE6', skin: '#E8B58A', hair: '#1F1B18', cloth: '#F5B301', style: 'buzz' },
  { key: 'u8', name: '刘海红', bg: '#FFF0EF', skin: '#FFD9B8', hair: '#4A2C20', cloth: '#E0202D', style: 'fringe' },
  { key: 'u9', name: '丸子青', bg: '#E9FAFC', skin: '#F7C79B', hair: '#2B211D', cloth: '#12B5CB', style: 'bun' },
  { key: 'u10', name: '胡子深蓝', bg: '#EDF2FA', skin: '#D9A278', hair: '#2A2622', cloth: '#35507A', style: 'beard' },
  { key: 'u11', name: '耳机薄荷', bg: '#EAFAF1', skin: '#FFDEC6', hair: '#3C2A1E', cloth: '#22C1C3', style: 'headphone' },
  { key: 'u12', name: '发带靛', bg: '#F0F1FF', skin: '#FFD9B8', hair: '#31251F', cloth: '#4C5BD4', style: 'band' },
];

function avatarSVG(a: AvatarSpec): string {
  const hair = a.hair;
  const eyes = `
    <circle cx="27.2" cy="27.5" r="1.6" fill="#3B2E2A"/>
    <circle cx="36.8" cy="27.5" r="1.6" fill="#3B2E2A"/>
    <path d="M28.6 32.6c2.1 1.7 4.7 1.7 6.8 0" stroke="#3B2E2A" stroke-width="1.7" stroke-linecap="round" fill="none"/>`;
  const shortHair = `<path d="M19.5 25.5c-.6-7.5 5-12.5 12.5-12.5s13.1 5 12.5 12.5c-1.2-3.4-4-5.2-7.2-5.6-2.6 1.4-7.6 1.8-10.8 0-3.2.4-6 2.2-7 5.6z" fill="${hair}"/>`;

  let extra = shortHair;
  switch (a.style) {
    case 'short':
    case 'glasses':
      extra = shortHair;
      break;
    case 'long':
      extra = `<path d="M19.5 25c0-8 5-13 12.5-13S44.5 17 44.5 25v12c0 2-1.5 3.1-3 2.2V27.5c-2.5 1.5-6.4 2-9.5.3V38c-1.5 1-3-.2-3-2.2V25z" fill="${hair}"/>`;
      break;
    case 'curly':
      extra = `<circle cx="20.5" cy="19" r="4" fill="${hair}"/><circle cx="26" cy="14.5" r="4.4" fill="${hair}"/><circle cx="33" cy="13.5" r="4.6" fill="${hair}"/><circle cx="39.5" cy="15.5" r="4.2" fill="${hair}"/><circle cx="44" cy="20.5" r="3.6" fill="${hair}"/><path d="M19.5 25.5c-.6-6 3-10.5 8-11.5 4 2 9 2 12.5 0 5 1 8.6 5.5 8 11.5-2-3-5-4.5-8.5-4.6-2.5 1.4-6.5 1.6-9.5.2-3.8.4-8.5 1.6-10.5 4.4z" fill="${hair}"/>`;
      break;
    case 'bun':
      extra = `<circle cx="32" cy="10" r="4.6" fill="${hair}"/><path d="M19.8 25.5c-.4-7 5-12 12.2-12s12.6 5 12.2 12c-1.6-3.2-4.4-5-7.6-5.4-2.6 1.3-6.6 1.6-9.4.1-3.3.4-6 2.2-7.4 5.3z" fill="${hair}"/>`;
      break;
    case 'cap':
      extra = `<path d="M18.5 24.5c0-8 6-13 13.5-13s13.5 5 13.5 13z" fill="${hair}"/><rect x="17" y="23" width="30" height="4.2" rx="2.1" fill="${hair}"/><circle cx="32" cy="9" r="2.2" fill="${hair}"/>`;
      break;
    case 'headphone':
      extra = `${shortHair}<path d="M18.5 28V23a13.5 13.5 0 0 1 27 0v5" stroke="${hair}" stroke-width="3.4" fill="none" stroke-linecap="round"/><rect x="15.5" y="25" width="6.5" height="10" rx="3.2" fill="${hair}"/><rect x="42" y="25" width="6.5" height="10" rx="3.2" fill="${hair}"/>`;
      break;
    case 'twintail':
      extra = `${shortHair}<circle cx="17.5" cy="21" r="4.2" fill="${hair}"/><circle cx="46.5" cy="21" r="4.2" fill="${hair}"/><rect x="14.8" y="23" width="4.4" height="12" rx="2.2" fill="${hair}"/><rect x="44.8" y="23" width="4.4" height="12" rx="2.2" fill="${hair}"/>`;
      break;
    case 'buzz':
      extra = `<path d="M19.8 24.8c0-6.4 5.4-10.8 12.2-10.8s12.2 4.4 12.2 10.8c-2.4-2.4-7-3.6-12.2-3.6s-9.8 1.2-12.2 3.6z" fill="${hair}"/>`;
      break;
    case 'fringe':
      extra = `<path d="M19.5 25.5c-.6-7.5 5-12.5 12.5-12.5s13.1 5 12.5 12.5c-1-3.2-3-5-5.6-5.6-4.5 3.4-13 3.4-16.4-.6-1.6 1.4-2.6 3.2-3 6.2z" fill="${hair}"/>`;
      break;
    case 'band':
      extra = `${shortHair}<path d="M18.8 21.5c8-3.4 18.4-3.4 26.4 0" stroke="${a.cloth}" stroke-width="3.6" stroke-linecap="round" fill="none"/>`;
      break;
  }

  let faceExtra = '';
  if (a.style === 'glasses') {
    faceExtra = `<circle cx="27" cy="27.5" r="4.6" stroke="#4A4F5A" stroke-width="1.5" fill="none"/><circle cx="37" cy="27.5" r="4.6" stroke="#4A4F5A" stroke-width="1.5" fill="none"/><path d="M31.6 27.5h.8" stroke="#4A4F5A" stroke-width="1.5"/>`;
  } else if (a.style === 'beard') {
    faceExtra = `<path d="M22 31.5c.6 7 4.6 10.2 10 10.2s9.4-3.2 10-10.2c-2 2.4-5.6 4-10 4s-8-1.6-10-4z" fill="${a.hair}" opacity=".92"/>`;
  }

  return `<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg"><circle cx="32" cy="32" r="32" fill="${a.bg}"/><path d="M13 58c1.6-9.5 9-14.5 19-14.5s17.4 5 19 14.5z" fill="${a.cloth}"/><circle cx="32" cy="27" r="13" fill="${a.skin}"/>${extra}${eyes}${faceExtra}</svg>`;
}

export const ICON_SEEDS: IconSeed[] = [
  ...TEAM_ICONS.map(([key, name, inner], i) => ({ key, kind: 'team' as IconKind, name, svg: s(inner), sort: i })),
  ...EMPLOYEE_ICONS.map(([key, name, inner], i) => ({ key, kind: 'employee' as IconKind, name, svg: s(inner), sort: i })),
  ...AVATAR_SPECS.map((a, i) => ({ key: a.key, kind: 'user' as IconKind, name: a.name, svg: avatarSVG(a), sort: i })),
];
