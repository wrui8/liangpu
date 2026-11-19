import 'models.dart';
import 'agent_models.dart';

/// 本地演示脚本：后端 Agent 接口就绪前，用它在客户端模拟流式回复与评论回复。
class AgentDemoScript {
  final List<String> tools;
  final String text;
  final List<AgentBlock> blocks;

  const AgentDemoScript({
    this.tools = const [],
    required this.text,
    this.blocks = const [],
  });
}

/// 按关键词生成一段有卡片、有跳转的演示回复
AgentDemoScript buildDemoChatReply(String input, AgentProfile agent) {
  final t = input.trim();

  if (t.contains('团队') ||
      t.contains('最高') ||
      t.contains('排名') ||
      t.contains('评分')) {
    return const AgentDemoScript(
      tools: ['正在查询团队评分…'],
      text: '我查了一下最近的评分（演示数据）：\n\n'
          '· 后端组 9.2 分，暂列第一\n'
          '· 产品组 8.7 分\n'
          '· 设计组 8.4 分\n\n'
          '后端组本周评分人数也在上涨，整体趋势向上。需要我展开某个团队的评分分布吗？',
      blocks: [
        AgentBlock(
          type: 'card',
          title: '后端组',
          route: 'team:1',
          fallback: '后端组 9.2 分 · 18 人评分 · 较上周 +0.3',
          fields: [
            AgentField(label: '当前评分', value: '9.2 分'),
            AgentField(label: '评分人数', value: '18 人'),
            AgentField(label: '本周趋势', value: '+0.3'),
          ],
        ),
        AgentBlock(
          type: 'actions',
          actions: [
            AgentActionItem(label: '查看后端组', route: 'team:1'),
            AgentActionItem(label: '看看需求广场', route: 'need:1'),
          ],
        ),
      ],
    );
  }

  if (t.contains('分析') || t.contains('得分') || t.contains('分布')) {
    return const AgentDemoScript(
      tools: ['正在分析评分分布…'],
      text: '从演示数据看，后端组的评分比较集中：\n\n'
          '· 9–10 分占比约 52%\n'
          '· 8 分档约 31%\n'
          '· 7 分及以下约 17%\n\n'
          '没有明显的低分拖累，整体口碑稳定。如果你愿意，我可以继续看看具体是哪几位同事拉高了团队分。',
      blocks: [
        AgentBlock(
          type: 'card',
          title: '后端组 · 评分分布',
          route: 'team:1',
          fallback: '后端组：9–10 分 52%，8 分 31%，7 分及以下 17%',
          fields: [
            AgentField(label: '9–10 分', value: '52%'),
            AgentField(label: '8 分', value: '31%'),
            AgentField(label: '7 分及以下', value: '17%'),
          ],
        ),
      ],
    );
  }

  if (t.contains('评论') || t.contains('发帖') || t.contains('发')) {
    return AgentDemoScript(
      text: '发评论有两种方式：\n\n'
          '1. 在评论区直接 @${agent.name}，我就会在评论里回复你；\n'
          '2. 在这里告诉我想发到哪条动态下、发什么内容。\n\n'
          '后端接入后，我会先检查权限，再按你的授权执行，并留下审计记录。',
      blocks: [
        AgentBlock(
          type: 'card',
          title: '写操作说明',
          fallback: '评论权限由管理端开关控制；用户 @ 即执行，限流并记录审计。',
          fields: [
            AgentField(label: '评论权限', value: agent.canComment ? '已开启' : '未开启'),
            AgentField(label: '触发方式', value: '@ 或面板指令'),
            AgentField(label: '审计', value: '服务端记录'),
          ],
        ),
      ],
    );
  }

  if (t.contains('能做什么') || t.contains('功能') || t.contains('会什么')) {
    return AgentDemoScript(
      text: '我现在可以帮你：\n\n'
          '· 查询团队、同事的评分与分布\n'
          '· 查看需求和平台动态\n'
          '· 分析得分变化，给出简短结论\n'
          '· 在评论区接 @，按授权代发评论\n\n'
          '名字、形象、知识库和权限都由管理端配置，后续加能力不需要你重新安装客户端。',
      blocks: const [
        AgentBlock(
          type: 'actions',
          actions: [
            AgentActionItem(label: '看看最高分团队', route: 'team:1'),
            AgentActionItem(label: '翻翻需求广场', route: 'need:1'),
          ],
        ),
      ],
    );
  }

  return AgentDemoScript(
    text: '${agent.greeting.isEmpty ? '我在。' : agent.greeting}\n\n'
        '你可以试试问我「本周评分最高的团队是谁」，或者直接在评论区 @${agent.name}。\n\n'
        '当前是前端演示模式，回复来自本地示例；后端接入后会自动切换为真实数据。',
    blocks: const [
      AgentBlock(
        type: 'card',
        title: '演示模式',
        fallback: '当前使用本地演示数据，后端接入后自动切换。',
        fields: [
          AgentField(label: '数据来源', value: '本地示例'),
          AgentField(label: '接入方式', value: 'OpenAI 兼容网关'),
          AgentField(label: '知识库', value: '待接入'),
        ],
      ),
    ],
  );
}

/// 评论区 @ 后生成的演示回复（≤120 字，符合评论长度限制）
String buildDemoCommentText(String input) {
  if (input.contains('评分') || input.contains('分')) {
    return '收到，我看了下最近的评分（演示数据）：后端组 9.2 分领先，产品组 8.7 分。想让我展开哪一项？';
  }
  if (input.contains('动态') || input.contains('这条')) {
    return '收到，这条动态我先记下了。等后端接入后，我可以直接查评分、看需求，也能在评论区继续回复你。';
  }
  return '收到，我先帮你留意着。接入后端后我就能实时查询评分、分析得分，还能按授权帮你发评论。';
}

/// 构造一条本地演示的 Agent 回复评论
Comment buildDemoAgentComment({
  required AgentProfile agent,
  required Comment parent,
  required String input,
}) {
  final id = -(DateTime.now().microsecondsSinceEpoch % 1000000000);
  return Comment(
    id: id,
    userId: agent.userId,
    user: agent.name,
    avatarIcon: '',
    score: 0,
    text: buildDemoCommentText(input),
    likes: 0,
    liked: false,
    parentId: parent.id,
    rootId: parent.rootId ?? parent.id,
    replyToUserId: parent.userId,
    replyToName: parent.user,
    replyCount: 0,
    replies: const [],
    createdAt: DateTime.now(),
    isAgent: true,
  );
}

/// 把文本切成小块，模拟流式输出（按 rune 切，中文不会乱码）
Iterable<String> demoTextChunks(String text, [int size = 3]) sync* {
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i += size) {
    final end = i + size > runes.length ? runes.length : i + size;
    yield String.fromCharCodes(runes.sublist(i, end));
  }
}
