import 'dart:convert';

/// 前端预览开关：后端 /api/agent/* 就绪前保持 true。
///
/// 为 true 时，meta 拉取失败会使用内置「小狮」演示配置与本地模拟回复；
/// 后端接入完成后改为 false，届时客户端只使用服务端下发的配置。
const bool kAgentPreview = true;

/// 聊天回复是否为客户端演示脚本。
///
/// 与 [kAgentPreview] 分开：服务端现已下发真实 meta（名称 / 形象 / 文案以管理端为准），
/// 但对话接口（SSE）尚未上线，回复仍由 `agent_demo.dart` 本地生成。
/// 服务端接入模型网关后把这里改成 false 即可切到真实对话。
const bool kAgentDemoChat = true;

num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
int _int(dynamic v) => _num(v).toInt();
String _str(dynamic v) => v == null ? '' : '$v';
bool _bool(dynamic v) => v == true || v == 'true';

List<String> _strings(dynamic v) => v is List
    ? v.map((e) => '$e').where((e) => e.isNotEmpty).toList()
    : const [];

/// 卡片里的一行「标签 / 值」
class AgentField {
  final String label;
  final String value;

  const AgentField({required this.label, required this.value});

  factory AgentField.fromJson(Map<String, dynamic> j) => AgentField(
        label: _str(j['label']),
        value: _str(j['value']),
      );
}

/// 卡片下方的跳转按钮
class AgentActionItem {
  final String label;
  final String? route;

  const AgentActionItem({required this.label, this.route});

  factory AgentActionItem.fromJson(Map<String, dynamic> j) => AgentActionItem(
        label: _str(j['label']),
        route: _str(j['route']).isEmpty ? null : _str(j['route']),
      );
}

/// 服务端下发的消息块。客户端只认 text / card / actions / error，
/// 其余类型用 fallback 降级，保证新能力不需要重发安装包。
class AgentBlock {
  final String type;
  final String text;
  final String title;
  final String? route;
  final String fallback;
  final List<AgentField> fields;
  final List<AgentActionItem> actions;

  const AgentBlock({
    required this.type,
    this.text = '',
    this.title = '',
    this.route,
    this.fallback = '',
    this.fields = const [],
    this.actions = const [],
  });

  factory AgentBlock.fromJson(Map<String, dynamic> j) {
    final kind = _str(j['type']);
    final fields = <AgentField>[];
    final actions = <AgentActionItem>[];
    if (j['fields'] is List) {
      for (final f in j['fields'] as List) {
        if (f is Map) {
          fields.add(AgentField.fromJson(Map<String, dynamic>.from(f)));
        }
      }
    }
    if (j['items'] is List) {
      for (final a in j['items'] as List) {
        if (a is Map) {
          actions.add(AgentActionItem.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
    final route = _str(j['route']);
    return AgentBlock(
      type: kind,
      text: _str(j['text']),
      title: _str(j['title']),
      route: route.isEmpty ? null : route,
      fallback: _str(j['fallback']),
      fields: fields,
      actions: actions,
    );
  }

  factory AgentBlock.error(String message) =>
      AgentBlock(type: 'error', text: message, fallback: message);

  bool get known =>
      type == 'text' || type == 'card' || type == 'actions' || type == 'error';
}

/// 单个 Agent 的公开配置（由 /api/agent/meta 下发）
class AgentProfile {
  final int id;
  final int userId;
  final String name;
  final List<String> aliases;
  final String? avatarUrl;
  final String avatarEmoji;
  final String intro;
  final String greeting;
  final List<String> suggestions;
  final bool canComment;
  final bool enabled;

  const AgentProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.aliases = const [],
    this.avatarUrl,
    this.avatarEmoji = '🦁',
    this.intro = '',
    this.greeting = '',
    this.suggestions = const [],
    this.canComment = true,
    this.enabled = true,
  });

  factory AgentProfile.fromJson(Map<String, dynamic> j) {
    final url = _str(j['avatarUrl']);
    return AgentProfile(
      id: _int(j['id']),
      userId: _int(j['userId']),
      name: _str(j['name']),
      aliases: _strings(j['aliases']),
      avatarUrl: url.isEmpty ? null : url,
      avatarEmoji: _str(j['avatarEmoji']).isEmpty ? '🦁' : _str(j['avatarEmoji']),
      intro: _str(j['intro']),
      greeting: _str(j['greeting']),
      suggestions: _strings(j['suggestions']),
      canComment: j['canComment'] == null ? true : _bool(j['canComment']),
      enabled: j['enabled'] == null ? true : _bool(j['enabled']),
    );
  }

  List<String> get allAliases {
    final out = <String>[];
    for (final a in [name, ...aliases]) {
      final v = a.trim();
      if (v.isNotEmpty && !out.contains(v)) out.add(v);
    }
    return out;
  }
}

/// Agent 全局元信息：名称、形象、别名、快捷指令、评论权限等
class AgentMeta {
  final bool enabled;
  final List<AgentProfile> agents;
  final int protocol;
  final int minClient;

  const AgentMeta({
    required this.enabled,
    required this.agents,
    this.protocol = 1,
    this.minClient = 1,
  });

  bool get hasAgent => enabled && agents.any((a) => a.enabled);

  AgentProfile? get primary {
    for (final a in agents) {
      if (a.enabled) return a;
    }
    return null;
  }

  AgentProfile? byUserId(int userId) {
    for (final a in agents) {
      if (a.userId == userId) return a;
    }
    return null;
  }

  /// 文本里是否 @ 了 Agent（与服务端别名兜底规则一致）
  bool matchesMention(String text) {
    if (!enabled) return false;
    final p = primary;
    if (p == null) return false;
    for (final alias in p.allAliases) {
      if (text.contains('@$alias')) return true;
    }
    return false;
  }

  factory AgentMeta.fromJson(Map<String, dynamic> j) => AgentMeta(
        enabled: j['enabled'] == null ? true : _bool(j['enabled']),
        agents: ((j['agents'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => AgentProfile.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        protocol: _int(j['protocol']),
        minClient: _int(j['minClient']),
      );

  /// 后端未接入时的内置演示配置。
  /// 名字、介绍、问候语在真实环境完全由管理端下发，客户端只负责渲染；
  /// 这里用同一个 name 变量拼接，避免演示文案里写死名字。
  factory AgentMeta.demo() {
    const name = '小狮';
    return const AgentMeta(
      enabled: true,
      protocol: 1,
      minClient: 1,
      agents: [
        AgentProfile(
          id: 1,
          userId: 900001,
          name: name,
          aliases: ['小狮子', '良扑小狮'],
          avatarEmoji: '🦁',
          intro: '我是良扑里的 AI 助手$name，能查团队评分、看需求、分析得分趋势，'
              '也能在评论区接住你的 @。',
          greeting: '嗨，我是$name。想看看谁的评分最高，还是让我帮你分析某个团队？',
          suggestions: [
            '本周评分最高的团队是谁？',
            '帮我分析一下后端组',
            '你能做什么？',
          ],
          canComment: true,
          enabled: true,
        ),
      ],
    );
  }
}

/// SSE 事件（客户端协议写死）
class AgentEvent {
  final String type;
  final Map<String, dynamic> data;

  const AgentEvent(this.type, this.data);

  factory AgentEvent.parse(String type, String raw) {
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = null;
    }
    if (decoded is Map) {
      return AgentEvent(type, Map<String, dynamic>.from(decoded));
    }
    return AgentEvent(type, {'text': raw});
  }
}
