import 'package:material_ui/material_ui.dart';

import '../../core/state.dart';
import 'agent_orb.dart';
import 'agent_panel.dart';

/// 全局 Agent 宿主：挂在 MaterialApp.builder 外层，
/// 让悬浮球与聊天面板跨越所有页面存在，且位于 Navigator 之上。
///
/// 自己套一层 Overlay：面板里的 Tooltip、输入框选区工具等都要求
/// 有 Overlay 祖先，而 builder 外层已经在 Navigator / Overlay 之上。
class AgentOverlayHost extends StatefulWidget {
  final Widget child;

  const AgentOverlayHost({super.key, required this.child});

  @override
  State<AgentOverlayHost> createState() => _AgentOverlayHostState();
}

class _AgentOverlayHostState extends State<AgentOverlayHost> {
  late final OverlayEntry _entry = OverlayEntry(builder: _buildOverlay);

  @override
  Widget build(BuildContext context) {
    return Overlay(initialEntries: [_entry]);
  }

  Widget _buildOverlay(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app.agentUi,
      builder: (context, _) {
        final meta = app.agentMeta;
        final agent = meta?.primary;
        final available =
            app.loggedIn && meta != null && meta.enabled && agent != null;
        final showOrb = available &&
            !app.agentUi.panelOpen &&
            !app.agentUi.cardOpen;
        final showPanel = available && app.agentUi.panelOpen;

        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (showOrb) AgentOrb(agent: agent),
            if (showPanel)
              Positioned.fill(
                child: AgentPanel(
                  agent: agent,
                  demo: app.agentDemoActive,
                  prefill: app.agentUi.prefill,
                  prefillSeq: app.agentUi.prefillSeq,
                ),
              ),
          ],
        );
      },
    );
  }
}
