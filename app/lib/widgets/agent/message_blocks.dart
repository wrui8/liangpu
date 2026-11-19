import 'package:material_ui/material_ui.dart';

import '../../core/agent_models.dart';
import '../../core/agent_routes.dart';
import '../../core/theme.dart';
import 'agent_avatar.dart';

/// Block 渲染器：text / card / actions / error 四种客户端写死，
/// 未知类型用 fallback 降级，服务端可以先加新能力、客户端后续再升级。
class AgentBlocksView extends StatelessWidget {
  final List<AgentBlock> blocks;

  const AgentBlocksView({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in blocks)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _render(context, b),
          ),
      ],
    );
  }

  Widget _render(BuildContext context, AgentBlock b) {
    return switch (b.type) {
      'text' => Text(
          b.text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.65,
            color: LpColors.of(context).text1,
          ),
        ),
      'card' => _card(context, b),
      'actions' => _actions(context, b),
      'error' => _error(context, b),
      _ => _fallback(context, b),
    };
  }

  Widget _card(BuildContext context, AgentBlock b) {
    final c = LpColors.of(context);
    final clickable = b.route != null && b.route!.isNotEmpty;
    return GestureDetector(
      onTap: clickable ? () => openAgentRoute(context, b.route) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: kAgentGold,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    b.title.isEmpty ? '详情' : b.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c.text1,
                    ),
                  ),
                ),
                if (clickable)
                  Text(
                    '›',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1,
                      color: c.text3,
                    ),
                  ),
              ],
            ),
            if (b.fields.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final f in b.fields)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          f.label,
                          style: TextStyle(fontSize: 11.5, color: c.text3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        f.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.text1,
                        ),
                      ),
                    ],
                  ),
                ),
            ] else if (b.fallback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  b.fallback,
                  style: TextStyle(fontSize: 11.5, color: c.text2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, AgentBlock b) {
    if (b.actions.isEmpty) return _fallback(context, b);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final a in b.actions)
          GestureDetector(
            onTap: a.route == null ? null : () => openAgentRoute(context, a.route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: kAgentGold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kAgentGold.withValues(alpha: 0.3)),
              ),
              child: Text(
                a.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: agentGoldText(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _error(BuildContext context, AgentBlock b) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              b.text.isEmpty ? '暂时无法完成，请稍后再试' : b.text,
              style: TextStyle(fontSize: 11.5, height: 1.5, color: c.text2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(BuildContext context, AgentBlock b) {
    final c = LpColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        b.fallback.isNotEmpty ? b.fallback : '当前版本暂不支持该内容，请升级客户端',
        style: TextStyle(fontSize: 11.5, height: 1.5, color: c.text2),
      ),
    );
  }
}
