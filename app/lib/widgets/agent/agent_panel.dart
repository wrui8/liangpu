import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/agent_models.dart';
import '../../core/agent_ui.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import 'agent_avatar.dart';
import 'agent_card_sheet.dart';
import 'agent_lion.dart';
import 'message_blocks.dart';

/// 迷你聊天面板：流式回复、block 渲染、快捷指令、移动端键盘避让。
class AgentPanel extends StatefulWidget {
  final AgentProfile agent;
  final bool demo;
  final String? prefill;
  final int prefillSeq;

  const AgentPanel({
    super.key,
    required this.agent,
    required this.demo,
    this.prefill,
    this.prefillSeq = 0,
  });

  @override
  State<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends State<AgentPanel> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  int _appliedPrefill = 0;

  @override
  void initState() {
    super.initState();
    _applyPrefill(force: true);
  }

  @override
  void didUpdateWidget(covariant AgentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefillSeq != widget.prefillSeq) _applyPrefill();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _applyPrefill({bool force = false}) {
    final seq = widget.prefillSeq;
    final text = widget.prefill;
    if (text == null || text.isEmpty) return;
    if (!force && seq == _appliedPrefill) return;
    _appliedPrefill = seq;
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _sendText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final app = AppScope.of(context);
    if (app.agentUi.streaming) return;
    app.agentUi.send(
      api: app.api,
      agent: widget.agent,
      demo: widget.demo,
      userName: app.user?.nickname ?? '你',
      text: text,
    );
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _sendText(text);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final ui = app.agentUi;

    return LayoutBuilder(
      builder: (context, cons) {
        final desktop = cons.maxWidth >= 700;
        final insets = MediaQuery.viewInsetsOf(context);
        final availH = math.max(240.0, cons.maxHeight - insets.bottom);
        final maxPanelH = math.max(220.0, availH - 20);
        final height = desktop
            ? math.min(560.0, maxPanelH)
            : math.min(availH * 0.74, maxPanelH);
        final width = desktop
            ? 392.0
            : math.min(cons.maxWidth - 20, 560.0);

        final panel = CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): ui.closePanel,
          },
          child: _panel(context, app, ui),
        );

        return Align(
          alignment: desktop ? Alignment.bottomRight : Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 12 + insets.bottom),
            child: SizedBox(width: width, height: height, child: panel),
          ),
        );
      },
    );
  }

  Widget _panel(BuildContext context, AppState app, AgentUiController ui) {
    final c = LpColors.of(context);
    return Material(
      color: c.surface,
      elevation: 24,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _header(context, ui),
          if (widget.demo) _demoBar(context),
          Container(height: 1, color: c.line),
          Expanded(
            child: ui.messages.isEmpty
                ? _empty(context, app, ui)
                : _messages(context, ui),
          ),
          _inputBar(context, ui),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AgentUiController ui) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kAgentGold.withValues(alpha: 0.16), c.surface],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => showAgentCard(
              context,
              widget.agent,
              demo: widget.demo,
            ),
            behavior: HitTestBehavior.opaque,
            child: AgentAvatar(agent: widget.agent, size: 34),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: c.text1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (widget.demo) const AgentBadge(text: '演示'),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.demo
                      ? '本地演示 · 名字与形象由管理端实时下发'
                      : '在线 · 可以问我评分、需求或评论',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: c.text3),
                ),
              ],
            ),
          ),
          _headerBtn(context, '↺', '新对话', ui.newChat),
          const SizedBox(width: 2),
          _headerBtn(context, '✕', '收起', ui.closePanel),
        ],
      ),
    );
  }

  Widget _headerBtn(
    BuildContext context,
    String glyph,
    String tip,
    VoidCallback onTap,
  ) {
    final c = LpColors.of(context);
    return Tooltip(
      message: tip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: Text(
            glyph,
            style: TextStyle(
              fontSize: glyph == '✕' ? 15 : 16,
              color: c.text2,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _demoBar(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: kAgentGold.withValues(alpha: 0.1),
      child: Text(
        '演示模式：回复来自本地示例，后端接入后自动切换为真实数据。',
        style: TextStyle(fontSize: 9.5, color: c.text3),
      ),
    );
  }

  Widget _empty(BuildContext context, AppState app, AgentUiController ui) {
    final c = LpColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((widget.agent.avatarUrl ?? '').isNotEmpty)
            AgentAvatar(agent: widget.agent, size: 56)
          else
            AnimatedLion(size: 56, thinking: ui.streaming),
          const SizedBox(height: 10),
          Text(
            widget.agent.greeting.isEmpty
                ? '你好，我是${widget.agent.name}。'
                : widget.agent.greeting,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: c.text1,
            ),
          ),
          if (widget.agent.intro.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.agent.intro,
              style: TextStyle(fontSize: 12, height: 1.7, color: c.text3),
            ),
          ],
          if (widget.agent.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '试试这样问',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: c.text3,
              ),
            ),
            const SizedBox(height: 8),
            for (final s in widget.agent.suggestions)
              GestureDetector(
                onTap: ui.streaming ? null : () => _sendText(s),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: c.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(fontSize: 12, color: c.text1),
                        ),
                      ),
                      Text(
                        '›',
                        style: TextStyle(fontSize: 16, color: c.text3),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _messages(BuildContext context, AgentUiController ui) {
    final reversed = ui.messages.reversed.toList();
    return ListView(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      children: [
        if (ui.streaming && ui.toolStatus != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 10),
            child: _toolLine(context, ui.toolStatus!),
          ),
        for (final m in reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _bubble(context, ui, m),
          ),
      ],
    );
  }

  Widget _toolLine(BuildContext context, String text) {
    return Row(
      children: [
        AgentAvatar(agent: widget.agent, size: 20),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: kAgentGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kAgentGold.withValues(alpha: 0.22)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: agentGoldText(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(
    BuildContext context,
    AgentUiController ui,
    AgentChatMessage m,
  ) {
    final c = LpColors.of(context);
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFE0202D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              m.text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    final placeholder = ui.toolStatus ?? '正在思考…';
    final display = m.text.isEmpty && m.streaming
        ? placeholder
        : '${m.text}${m.streaming ? '▍' : ''}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentAvatar(agent: widget.agent, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.text.isNotEmpty || m.streaming)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                      topRight: Radius.circular(13),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(13),
                    ),
                    border: Border.all(color: c.line),
                  ),
                  child: Text(
                    display,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      color: c.text1,
                    ),
                  ),
                ),
              if (m.blocks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 2),
                  child: AgentBlocksView(blocks: m.blocks),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputBar(BuildContext context, AgentUiController ui) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): _send,
                const SingleActivator(LogicalKeyboardKey.numpadEnter): _send,
              },
              child: TextField(
                controller: _input,
                focusNode: _focus,
                maxLength: 600,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: TextStyle(fontSize: 13, color: c.text1, height: 1.5),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: c.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '问问${widget.agent.name}…',
                  hintStyle: TextStyle(fontSize: 12.5, color: c.text3),
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: ui.streaming ? null : _send,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ui.streaming ? c.line : c.brand,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                ui.streaming ? '…' : '↑',
                style: TextStyle(
                  fontSize: 17,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: ui.streaming ? c.text3 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
