import 'package:material_ui/material_ui.dart';

import '../../core/state.dart';
import 'agent_avatar.dart';

/// 评论 / 回复 / 短评输入框旁的「@小狮」按钮。
/// 名称来自服务端 meta，管理端改名后这里自动跟着变。
class AgentMentionButton extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool compact;

  const AgentMentionButton({
    super.key,
    required this.controller,
    this.focusNode,
    this.compact = false,
  });

  void _insertMention(String name) {
    final value = controller.value;
    final text = value.text;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : start;
    final before = text.substring(0, start);
    final needSpace =
        before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('\n');
    final insert = '${needSpace ? ' ' : ''}@$name ';
    final next = text.replaceRange(start, end, insert);
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    focusNode?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final meta = app.agentMeta;
    final agent = meta?.primary;
    if (!app.loggedIn || meta == null || !meta.hasAgent || agent == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _insertMention(agent.name),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: kAgentGold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kAgentGold.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              agent.avatarEmoji.isEmpty ? '🦁' : agent.avatarEmoji,
              style: TextStyle(fontSize: compact ? 11 : 12, height: 1),
            ),
            const SizedBox(width: 4),
            Text(
              compact ? '@${agent.name}' : '呼叫 ${agent.name}',
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: agentGoldText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
