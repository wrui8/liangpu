import 'dart:async';

import 'package:flutter/foundation.dart';

import 'agent_demo.dart';
import 'agent_models.dart';
import 'api.dart';

/// 面板里的一条消息（用户或 Agent）
class AgentChatMessage {
  final bool fromUser;
  String text;
  final List<AgentBlock> blocks;
  bool streaming;

  AgentChatMessage({
    required this.fromUser,
    this.text = '',
    List<AgentBlock>? blocks,
    this.streaming = false,
  }) : blocks = blocks ?? [];
}

/// 悬浮球 / 面板的全局状态。由 AppState 持有，跨页面共享。
class AgentUiController extends ChangeNotifier {
  bool panelOpen = false;

  /// 名片弹层打开时暂时收起悬浮球，避免挡在卡片上方
  bool cardOpen = false;
  String? prefill;
  int prefillSeq = 0;

  final List<AgentChatMessage> messages = [];
  bool streaming = false;
  String? toolStatus;

  int? _conversationId;
  int? _agentId;
  int _run = 0;

  void openPanel({String? prefillText}) {
    if (prefillText != null && prefillText.trim().isNotEmpty) {
      prefill = prefillText.trim();
      prefillSeq++;
    }
    panelOpen = true;
    notifyListeners();
  }

  void closePanel() {
    if (!panelOpen) return;
    panelOpen = false;
    notifyListeners();
  }

  /// 打开名片：先收起聊天面板，再隐藏悬浮球，卡片关闭后恢复
  void beginCard() {
    panelOpen = false;
    cardOpen = true;
    notifyListeners();
  }

  void endCard() {
    if (!cardOpen) return;
    cardOpen = false;
    notifyListeners();
  }

  /// 清空当前会话，保留面板打开状态
  void newChat() {
    _run++;
    messages.clear();
    streaming = false;
    toolStatus = null;
    _conversationId = null;
    _agentId = null;
    notifyListeners();
  }

  /// 退出登录 / 换服务器时彻底复位
  void reset() {
    _run++;
    messages.clear();
    streaming = false;
    toolStatus = null;
    panelOpen = false;
    cardOpen = false;
    prefill = null;
    prefillSeq = 0;
    _conversationId = null;
    _agentId = null;
    notifyListeners();
  }

  bool _alive(int run) => run == _run;

  Future<void> send({
    required Api api,
    required AgentProfile agent,
    required bool demo,
    required String userName,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty || streaming) return;

    messages.add(AgentChatMessage(fromUser: true, text: content));
    final reply = AgentChatMessage(fromUser: false, streaming: true);
    messages.add(reply);
    streaming = true;
    toolStatus = null;
    final run = ++_run;
    notifyListeners();

    try {
      if (demo) {
        await _demoReply(agent: agent, reply: reply, content: content, run: run);
      } else {
        await _realReply(
          api: api,
          agent: agent,
          reply: reply,
          content: content,
          run: run,
        );
      }
    } catch (e) {
      if (run == _run) {
        reply.blocks.add(
          AgentBlock.error(
            e is ApiException ? e.message : 'Agent 暂时不可用，请稍后再试',
          ),
        );
      }
    } finally {
      if (run == _run) {
        streaming = false;
        toolStatus = null;
        reply.streaming = false;
        notifyListeners();
      }
    }
  }

  Future<void> _demoReply({
    required AgentProfile agent,
    required AgentChatMessage reply,
    required String content,
    required int run,
  }) async {
    final script = buildDemoChatReply(content, agent);
    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!_alive(run)) return;

    for (final tool in script.tools) {
      toolStatus = tool;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 560));
      if (!_alive(run)) return;
    }
    toolStatus = null;
    notifyListeners();

    for (final chunk in demoTextChunks(script.text)) {
      if (!_alive(run)) return;
      reply.text += chunk;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 24));
    }

    for (final block in script.blocks) {
      if (!_alive(run)) return;
      reply.blocks.add(block);
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
  }

  Future<void> _realReply({
    required Api api,
    required AgentProfile agent,
    required AgentChatMessage reply,
    required String content,
    required int run,
  }) async {
    if (_conversationId == null || _agentId != agent.id) {
      _conversationId = await api.createAgentConversation(agent.id);
      _agentId = agent.id;
    }
    final convId = _conversationId!;

    await for (final ev in api.streamAgentMessage(
      conversationId: convId,
      content: content,
    )) {
      if (!_alive(run)) return;
      switch (ev.type) {
        case 'delta':
          reply.text += '${ev.data['text'] ?? ''}';
        case 'block':
          reply.blocks.add(AgentBlock.fromJson(ev.data));
        case 'tool':
          final name = '${ev.data['name'] ?? ''}';
          final status = '${ev.data['status'] ?? ''}';
          toolStatus = status == 'done' ? null : _toolLabel(name);
        case 'error':
          final msg = '${ev.data['message'] ?? 'Agent 服务返回错误'}';
          reply.blocks.add(AgentBlock.error(msg));
        default:
          break;
      }
      notifyListeners();
    }
  }

  String _toolLabel(String name) => switch (name) {
        'list_teams' => '正在查询团队…',
        'get_team' => '正在查看团队详情…',
        'get_employee' => '正在查看同事评分…',
        'search_needs' => '正在翻需求广场…',
        'list_posts' => '正在看平台动态…',
        'get_post' => '正在看这条动态…',
        'create_comment' => '正在发评论…',
        _ => '正在处理…',
      };
}
