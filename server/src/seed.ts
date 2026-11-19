import './env';
import bcrypt from 'bcryptjs';
import { prisma } from './db';
import { ICON_SEEDS } from './icons';

const AVATAR_COLORS: Array<[string, string]> = [
  ['#8E9BFF', '#5B6CFF'], ['#FFB36B', '#FF7A45'], ['#6BD9B5', '#2BC48A'],
  ['#FF9AA2', '#F23441'], ['#7FC8F8', '#12B5CB'], ['#C9A7FF', '#8E4DFF'],
];

function colorFor(name: string): [string, string] {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return AVATAR_COLORS[h % AVATAR_COLORS.length];
}

function distFromPct(pct: number[], count: number): number[] {
  const arr = pct.map(p => Math.max(0, Math.round((p / 100) * count)));
  const diff = count - arr.reduce((a, b) => a + b, 0);
  arr[9] = Math.max(0, arr[9] + diff);
  return arr;
}

interface SeedComment { user: string; score: number; text: string; likes: number; days: number }
interface SeedEmp { name: string; title: string; score: number; count: number }

interface SeedTeam {
  name: string; category: 'c' | '中'; short: string; iconKey: string;
  c1: string; c2: string; score: number; count: number; dist: number[];
  tags: string[]; comments: SeedComment[]; employees: SeedEmp[];
}

const TEAMS: SeedTeam[] = [
  {
    name: '小狮达', category: 'c', short: '狮', iconKey: 'crown', c1: '#F5A623', c2: '#F76B1C', score: 8.7, count: 96,
    dist: [1, 1, 1, 2, 3, 5, 10, 20, 27, 30],
    tags: ['体验好', '迭代快', '沟通顺畅'],
    comments: [
      { user: '夜跑的风', score: 10, text: '需求响应特别快，小版本一周一个，体验越来越顺。', likes: 36, days: 0.1 },
      { user: '一只小橘', score: 9, text: '产品设计很细腻，细节能感觉到是用心打磨过的。', likes: 21, days: 0.3 },
      { user: '可乐不加冰', score: 8, text: '整体不错，就是文档偶尔更新不及时。', likes: 11, days: 1 },
    ],
    employees: [
      { name: '米威', title: '产品负责人', score: 9.0, count: 26 },
      { name: '顺风尧', title: '产品经理', score: 8.8, count: 21 },
      { name: '京涛', title: '交互设计', score: 8.7, count: 18 },
      { name: '河马锋', title: '视觉设计', score: 8.6, count: 16 },
      { name: '粤涛', title: '用户研究', score: 8.5, count: 14 },
      { name: '慈闻', title: '数据分析', score: 8.4, count: 13 },
      { name: '大0子', title: '运营', score: 8.3, count: 12 },
      { name: '大帅兄', title: '市场', score: 8.2, count: 11 },
      { name: '蛋', title: '产品助理', score: 8.1, count: 9 },
    ],
  },
  {
    name: '小师富', category: 'c', short: '师', iconKey: 'wrench', c1: '#2BC48A', c2: '#0EA679', score: 8.4, count: 78,
    dist: [1, 1, 2, 2, 4, 7, 14, 24, 25, 20],
    tags: ['专业', '响应及时', '方案清晰'],
    comments: [
      { user: '打工人小陈', score: 9, text: '疑难问题找到小师富团队，基本都能给出可落地的方案。', likes: 24, days: 0.2 },
      { user: '木木夕', score: 8, text: '专业没得说，预约高峰期要排队久一点。', likes: 9, days: 1 },
    ],
    employees: [
      { name: '夜露', title: '产品经理', score: 8.6, count: 15 },
    ],
  },
  {
    name: '订单中心', category: '中', short: '单', iconKey: 'box', c1: '#5B6CFF', c2: '#8E4DFF', score: 8.1, count: 112,
    dist: [2, 2, 3, 4, 6, 10, 18, 24, 18, 13],
    tags: ['稳定', '处理快', '抗压强'],
    comments: [
      { user: '橙子汽水', score: 9, text: '大促期间订单零丢失，当天全部处理完，稳。', likes: 33, days: 0.1 },
      { user: '大熊', score: 8, text: '异常订单跟进及时，月底对账稍微慢一点。', likes: 14, days: 0.5 },
    ],
    employees: [
      { name: '劳模德', title: '订单主管', score: 8.4, count: 22 },
      { name: '芒柠锋', title: '订单专员', score: 8.1, count: 18 },
    ],
  },
  {
    name: 'HR', category: '中', short: 'H', iconKey: 'users', c1: '#FF6B8B', c2: '#E64367', score: 8.3, count: 65,
    dist: [1, 1, 2, 2, 4, 7, 15, 24, 25, 19],
    tags: ['流程规范', '态度友好', '效率不错'],
    comments: [
      { user: '打工人小陈', score: 9, text: '入职手续半小时办完，资料清单提前发得很清楚。', likes: 21, days: 0.25 },
      { user: '摸鱼专家', score: 8, text: '社保公积金问题回复及时，就是座机经常占线。', likes: 12, days: 1 },
    ],
    employees: [
      { name: '伟妈', title: '招聘主管', score: 8.5, count: 16 },
      { name: '早上下雨', title: 'HRBP', score: 8.2, count: 12 },
    ],
  },
  {
    name: '监', category: '中', short: '监', iconKey: 'shield', c1: '#12B5CB', c2: '#3B6DF0', score: 7.8, count: 54,
    dist: [2, 2, 3, 5, 8, 12, 20, 22, 16, 10],
    tags: ['严谨', '合规', '原则性强'],
    comments: [
      { user: '北方的狼', score: 8, text: '抽查反馈很专业，问题定位准，给出的整改建议也清楚。', likes: 10, days: 0.4 },
      { user: '一只小橘', score: 7, text: '流程有点严格，但想想也是应该的。', likes: 7, days: 2 },
    ],
    employees: [
      { name: '问滔', title: '风控专员', score: 7.9, count: 14 },
    ],
  },
  {
    name: 'ai', category: '中', short: 'A', iconKey: 'chip', c1: '#7C4DFF', c2: '#00B8D4', score: 8.9, count: 140,
    dist: [1, 0, 1, 1, 2, 4, 9, 19, 30, 33],
    tags: ['能力强', '落地快', '文档完善'],
    comments: [
      { user: '可乐不加冰', score: 10, text: '接入不到两周就跑通了业务场景，效果立竿见影。', likes: 49, days: 0.1 },
      { user: '夜跑的风', score: 9, text: '技术分享做得很好，普通同事也能听懂并上手。', likes: 27, days: 0.4 },
      { user: '三三', score: 8, text: '算力紧张的时候排队有点久，其他都好。', likes: 13, days: 1 },
    ],
    employees: [
      { name: '一手遮天张', title: 'AI 负责人', score: 9.0, count: 28 },
      { name: '空气黄', title: '算法工程师', score: 8.8, count: 23 },
    ],
  },
  {
    name: '测试', category: '中', short: '测', iconKey: 'flask', c1: '#22C1C3', c2: '#0B8FA8', score: 7.9, count: 88,
    dist: [2, 2, 3, 5, 7, 12, 19, 23, 17, 10],
    tags: ['把关严', '用例全', '反馈快'],
    comments: [
      { user: '大熊', score: 9, text: '上线前拦下好几个边界问题，找测试就图个安心。', likes: 25, days: 0.2 },
      { user: '一只小橘', score: 7, text: '执着是好事，但有时候卡得太细影响发布节奏。', likes: 12, days: 1 },
    ],
    employees: [
      { name: '尾灯习', title: '测试主管', score: 8.0, count: 20 },
      { name: '围巾', title: '测试工程师', score: 7.8, count: 18 },
    ],
  },
  {
    name: '前端', category: '中', short: '前', iconKey: 'code', c1: '#5B6CFF', c2: '#9B5CFF', score: 8.6, count: 128,
    dist: [1, 1, 1, 2, 3, 5, 9, 18, 27, 33],
    tags: ['还原度高', '响应快', '体验细腻'],
    comments: [
      { user: '夜跑的风', score: 10, text: '设计稿还原度很高，动效做得流畅，用户反馈不错。', likes: 42, days: 0.1 },
      { user: '可乐不加冰', score: 9, text: '兼容性问题当天修，联调配合很默契。', likes: 28, days: 0.5 },
    ],
    employees: [
      { name: '皮皮', title: '前端负责人', score: 8.7, count: 24 },
      { name: '三三', title: '前端工程师', score: 8.4, count: 19 },
    ],
  },
  {
    name: '架构', category: '中', short: '架', iconKey: 'layers', c1: '#5A6B8C', c2: '#35415C', score: 8.5, count: 73,
    dist: [1, 1, 1, 2, 4, 6, 11, 21, 27, 26],
    tags: ['方案扎实', '视野高', '文档清晰'],
    comments: [
      { user: '北方的狼', score: 9, text: '架构评审把潜在坑都提前讲了，避开了不少返工。', likes: 19, days: 0.3 },
      { user: '木木夕', score: 8, text: '方案很稳，就是有时追求完美导致评审周期偏长。', likes: 8, days: 2 },
    ],
    employees: [
      { name: '良强', title: '首席架构师', score: 8.8, count: 22 },
      { name: '祁连浩', title: '架构师', score: 8.6, count: 18 },
      { name: '企鹅王', title: '基础架构', score: 8.4, count: 14 },
    ],
  },
  {
    name: '闪购', category: 'c', short: '闪', iconKey: 'bolt', c1: '#FFB300', c2: '#FF6D00', score: 8.8, count: 154,
    dist: [1, 0, 1, 1, 2, 4, 8, 19, 29, 35],
    tags: ['爆发力强', '选品好', '活动多'],
    comments: [
      { user: '橙子汽水', score: 10, text: '这次闪购活动的节奏铺得特别好，爆品一个接一个。', likes: 46, days: 0.1 },
      { user: '一只小橘', score: 9, text: '选品越来越准，同事群里天天有人晒单。', likes: 23, days: 0.3 },
    ],
    employees: [
      { name: '积木曾', title: '闪购负责人', score: 8.9, count: 30 },
      { name: '犯错明', title: '运营经理', score: 8.7, count: 25 },
      { name: '坑哥', title: '活动策划', score: 8.5, count: 20 },
    ],
  },
  {
    name: '数仓', category: '中', short: '数', iconKey: 'database', c1: '#2E9CCA', c2: '#1467A8', score: 8.2, count: 86,
    dist: [2, 1, 2, 3, 5, 9, 17, 25, 21, 15],
    tags: ['口径统一', '出数快', '数据准确'],
    comments: [
      { user: '木木夕', score: 9, text: '取数需求当天就有反馈，口径文档也比以前清楚多了。', likes: 19, days: 0.2 },
      { user: '北方的狼', score: 8, text: '大表查询有时候偏慢，但数据质量确实稳。', likes: 8, days: 1 },
    ],
    employees: [],
  },
  {
    name: '离殇', category: '中', short: '离', iconKey: 'wind', c1: '#B06BE8', c2: '#6D4CFF', score: 8.4, count: 62,
    dist: [1, 1, 2, 2, 4, 7, 15, 25, 25, 18],
    tags: ['氛围好', '协作顺', '爆发力强'],
    comments: [
      { user: '大熊', score: 9, text: '配合度很高，临时拉群支援从不推脱，靠谱。', likes: 17, days: 0.3 },
      { user: '一只小橘', score: 8, text: '人不多但都能打，就是排期偶尔撞车。', likes: 7, days: 1 },
    ],
    employees: [
      { name: '干部郭', title: '负责人', score: 8.6, count: 12 },
      { name: '小0子', title: '运营', score: 8.4, count: 10 },
      { name: '瑟图豪', title: '内容', score: 8.2, count: 9 },
      { name: '保研龙', title: '社群', score: 8.0, count: 8 },
    ],
  },
];

interface SeedNeed {
  title: string; desc: string; category: string; status: string;
  team: string; proposer: string; score: number; count: number; dist: number[];
  tags: string[]; days: number;
  members: Array<{ team: string; name: string; role: '提议' | '负责' | '参与' }>;
  comments: SeedComment[];
}

const NEEDS: SeedNeed[] = [
  {
    title: '会议室预订支持手机端一键预约',
    desc: '现在订会议室只能到前台登记或者找行政同事帮忙，经常出现撞会的情况。希望能像点外卖一样，在手机上看到空闲会议室并直接预约，冲突自动提醒。',
    category: '办公效率', status: '评审中', team: 'HR', proposer: '早上下雨',
    score: 8.3, count: 32, dist: [1, 1, 2, 3, 6, 10, 18, 24, 20, 15],
    tags: ['高频', '影响多人', '行政效率'], days: 3,
    members: [
      { team: 'HR', name: '早上下雨', role: '提议' },
      { team: 'HR', name: '伟妈', role: '负责' },
    ],
    comments: [
      { user: '打工人小陈', score: 9, text: '太需要了，午休时间根本抢不到会议室。', likes: 18, days: 1 },
      { user: '北方的狼', score: 8, text: '顺便把投影设备状态也能看到就更好了。', likes: 9, days: 2 },
    ],
  },
  {
    title: '报销流程支持电子发票自动识别',
    desc: '每月月底报销单数量大，手工录入发票信息耗时且容易出错。希望上传电子发票后自动识别金额、日期和税号，直接生成报销单。',
    category: '财务流程', status: '进行中', team: '小师富', proposer: '夜露',
    score: 7.8, count: 21, dist: [2, 2, 3, 5, 8, 12, 20, 22, 16, 10],
    tags: ['降本增效', '财务'], days: 7,
    members: [{ team: '小师富', name: '夜露', role: '提议' }],
    comments: [
      { user: '大熊', score: 9, text: '上线后估计能省一半时间，期待。', likes: 14, days: 3 },
    ],
  },
  {
    title: '研发区 Wi-Fi 信号增强',
    desc: '研发区靠窗工位 Wi-Fi 经常掉线，影响联调和测试。希望增加 AP 或调整信号覆盖。',
    category: '网络环境', status: '已完成', team: '架构', proposer: '良强',
    score: 9.0, count: 45, dist: [1, 0, 1, 1, 2, 4, 8, 18, 30, 35],
    tags: ['已解决', '体验提升'], days: 14,
    members: [
      { team: '架构', name: '良强', role: '提议' },
      { team: '架构', name: '企鹅王', role: '负责' },
      { team: '架构', name: '祁连浩', role: '参与' },
    ],
    comments: [
      { user: '夜跑的风', score: 10, text: '已经加装了两个 AP，现在满格，给行政和 IT 点赞。', likes: 31, days: 5 },
    ],
  },
  {
    title: '团队评分结果支持月度导出',
    desc: '每月例会前都要手动截图整理各团队评分，希望支持导出 Excel 或 PDF 报表，包含均分、分布和亮评摘要。',
    category: '数据报表', status: '评审中', team: 'ai', proposer: '空气黄',
    score: 7.5, count: 12, dist: [3, 3, 4, 5, 7, 11, 20, 21, 15, 11],
    tags: ['数据', '例会'], days: 2,
    members: [
      { team: 'ai', name: '空气黄', role: '提议' },
      { team: 'ai', name: '一手遮天张', role: '负责' },
    ],
    comments: [
      { user: '三三', score: 8, text: '例会刚需，每次整理半小时。', likes: 5, days: 1 },
    ],
  },
];

const daysAgo = (d: number) => new Date(Date.now() - d * 24 * 3600 * 1000);

async function main() {
  console.log('清空旧数据…');
  await prisma.commentLike.deleteMany();
  await prisma.comment.deleteMany();
  await prisma.rating.deleteMany();
  await prisma.needMember.deleteMany();
  await prisma.employee.deleteMany();
  await prisma.need.deleteMany();
  await prisma.team.deleteMany();
  await prisma.user.deleteMany();
  await prisma.icon.deleteMany();

  console.log('写入图标池…');
  for (const icon of ICON_SEEDS) {
    await prisma.icon.create({
      data: { key: icon.key, kind: icon.kind, name: icon.name, svg: icon.svg, sort: icon.sort },
    });
  }

  console.log('创建账号…');
  const adminPwd = await bcrypt.hash('admin123', 10);
  const demoPwd = await bcrypt.hash('demo123', 10);
  await prisma.user.create({
    data: { username: 'admin', password: adminPwd, nickname: '管理员', role: 'admin', avatarIcon: 'u10' },
  });
  await prisma.user.create({
    data: { username: 'demo', password: demoPwd, nickname: 'JR_9527', role: 'user', avatarIcon: 'u1' },
  });

  /* 评论者账号 */
  const userMap = new Map<string, number>();
  const demoUser = await prisma.user.findUnique({ where: { username: 'demo' } });
  if (demoUser) userMap.set('JR_9527', demoUser.id);

  let vIndex = 0;
  const nicknames = new Set<string>();
  for (const t of TEAMS) for (const c of t.comments) nicknames.add(c.user);
  for (const n of NEEDS) for (const c of n.comments) nicknames.add(c.user);
  for (const nick of nicknames) {
    if (userMap.has(nick)) continue;
    vIndex += 1;
    const u = await prisma.user.create({
      data: {
        username: `user${String(vIndex).padStart(2, '0')}`,
        password: demoPwd,
        nickname: nick,
        avatarIcon: `u${((vIndex - 1) % 12) + 1}`,
      },
    });
    userMap.set(nick, u.id);
  }

  console.log('写入团队 / 员工…');
  const teamIdByName = new Map<string, number>();
  const empIdByKey = new Map<string, number>();

  for (let ti = 0; ti < TEAMS.length; ti++) {
    const t = TEAMS[ti];
    const team = await prisma.team.create({
      data: {
        name: t.name, category: t.category, short: t.short, iconKey: t.iconKey,
        color1: t.c1, color2: t.c2, score: t.score, ratingCount: t.count,
        dist: JSON.stringify(distFromPct(t.dist, t.count)),
        tags: JSON.stringify(t.tags), sort: ti,
      },
    });
    teamIdByName.set(t.name, team.id);

    for (let ei = 0; ei < t.employees.length; ei++) {
      const e = t.employees[ei];
      const [c1, c2] = colorFor(e.name);
      const emp = await prisma.employee.create({
        data: {
          teamId: team.id, name: e.name, title: e.title,
          color1: c1, color2: c2, score: e.score, ratingCount: e.count,
          dist: JSON.stringify(distFromPct([1, 1, 2, 3, 5, 8, 15, 25, 25, 15], e.count)),
          sort: ei,
        },
      });
      empIdByKey.set(`${t.name}/${e.name}`, emp.id);
    }

    for (const c of t.comments) {
      await prisma.comment.create({
        data: {
          userId: userMap.get(c.user)!,
          targetType: 'team', targetId: team.id,
          score: c.score, content: c.text, likes: c.likes,
          createdAt: daysAgo(c.days),
        },
      });
    }
  }

  console.log('写入需求…');
  for (let ni = 0; ni < NEEDS.length; ni++) {
    const n = NEEDS[ni];
    const need = await prisma.need.create({
      data: {
        title: n.title, desc: n.desc, category: n.category, status: n.status,
        teamId: teamIdByName.get(n.team) ?? null, proposerName: n.proposer,
        score: n.score, voteCount: n.count,
        dist: JSON.stringify(distFromPct(n.dist, n.count)),
        tags: JSON.stringify(n.tags), sort: ni,
        createdAt: daysAgo(n.days),
      },
    });
    let mi = 0;
    for (const m of n.members) {
      const empId = empIdByKey.get(`${m.team}/${m.name}`);
      if (!empId) continue;
      await prisma.needMember.create({
        data: { needId: need.id, employeeId: empId, role: m.role, sort: mi++ },
      });
    }
    for (const c of n.comments) {
      await prisma.comment.create({
        data: {
          userId: userMap.get(c.user)!,
          targetType: 'need', targetId: need.id,
          score: c.score, content: c.text, likes: c.likes,
          createdAt: daysAgo(c.days),
        },
      });
    }
  }

  /* 平台动态演示数据（首次启动才有；真实动态由用户自行发布） */
  const postSeeds = [
    { user: 'JR_9527', likes: 26, days: 0.2, text: '良扑上线啦！给身边的团队和同事打分，也能在这里发动态。\n今天先给「小狮达」打了个 9 分，迭代速度是真的快。' },
    { user: '夜跑的风', likes: 18, days: 0.6, text: '需求广场里那条「首页加载优化」支持度已经冲到前面了，\n大家的票真的有用，期待下个版本。' },
    { user: '一只小橘', likes: 9, days: 1.4, text: '中午在茶水间听到好几个同事在聊良扑的亮评，\n比想象中热闹，记得理性打分、友善发言。' },
    { user: '打工人小陈', likes: 4, days: 2.3, text: '第一次发动态，打个卡。\n希望后面能加上配图，把团建照片发上来。' },
  ];
  for (const p of postSeeds) {
    const uid = userMap.get(p.user);
    if (!uid) continue;
    await prisma.post.create({
      data: {
        userId: uid,
        content: p.text,
        likes: p.likes, // 展示计数，演示数据不落 PostLike，避免与真实点赞混淆
        createdAt: daysAgo(p.days),
      },
    });
  }

  console.log('');
  console.log('  种子数据完成');
  console.log('  管理端账号  admin / admin123');
  console.log('  演示账号    demo  / demo123');
  console.log('');
}

main()
  .catch(err => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
