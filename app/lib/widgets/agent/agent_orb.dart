import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/agent_models.dart';
import '../../core/state.dart';
import 'agent_avatar.dart';
import 'agent_card_sheet.dart';
import 'agent_lion.dart';

/// 可拖动的小狮子悬浮球：位置持久化，点击开面板，长按看名片。
class AgentOrb extends StatefulWidget {
  final AgentProfile agent;

  const AgentOrb({super.key, required this.agent});

  @override
  State<AgentOrb> createState() => _AgentOrbState();
}

class _AgentOrbState extends State<AgentOrb>
    with SingleTickerProviderStateMixin {
  static const double _size = 62;
  static const String _kPosX = 'lp_agent_orb_x';
  static const String _kPosY = 'lp_agent_orb_y';

  Offset? _pos;
  bool _dragging = false;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Offset _clamp(Offset p, Size area) {
    final maxX = math.max(12.0, area.width - _size - 12);
    final maxY = math.max(72.0, area.height - _size - 94);
    return Offset(
      p.dx.clamp(12.0, maxX),
      p.dy.clamp(72.0, maxY),
    );
  }

  Offset _initial(AppState app, Size area) {
    final x = app.prefs.getDouble(_kPosX);
    final y = app.prefs.getDouble(_kPosY);
    if (x != null && y != null) {
      return _clamp(Offset(x * area.width, y * area.height), area);
    }
    return _clamp(
      Offset(area.width - _size - 22, area.height * 0.68),
      area,
    );
  }

  void _save(AppState app, Size area) {
    final p = _pos;
    if (p == null) return;
    app.prefs.setDouble(_kPosX, (p.dx / area.width).clamp(0.0, 1.0));
    app.prefs.setDouble(_kPosY, (p.dy / area.height).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, cons) {
          final area = Size(cons.maxWidth, cons.maxHeight);
          _pos ??= _initial(app, area);
          final pos = _clamp(_pos!, area);
          _pos = pos;

          return Stack(
            children: [
              Positioned(
                left: pos.dx,
                top: pos.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => app.openAgentPanel(),
                  onLongPress: () => showAgentCard(
                    context,
                    widget.agent,
                    demo: app.agentDemoActive,
                  ),
                  onPanStart: (_) => setState(() => _dragging = true),
                  onPanUpdate: (d) {
                    setState(() {
                      _pos = _clamp((_pos ?? pos) + d.delta, area);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() => _dragging = false);
                    _save(app, area);
                  },
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 160),
                    scale: _dragging ? 1.08 : 1,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.scale(
                        scale: 1 + 0.045 * _pulse.value,
                        child: child,
                      ),
                      child: _orb(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orb(BuildContext context) {
    final app = AppScope.of(context);
    final hasUpload = (widget.agent.avatarUrl ?? '').isNotEmpty;
    // 不放圆形底板/描边，也不放「AI」角标：让角色独立地浮在界面上
    return SizedBox(
      width: _size,
      height: _size,
      child: Center(
        // 管理端上传了头像就用图片；否则用会动的小狮子（悬浮/呼吸/眨眼）
        child: hasUpload
            ? AgentAvatar(agent: widget.agent, size: 56)
            : AnimatedLion(
                size: 56,
                thinking: app.agentUi.streaming,
              ),
      ),
    );
  }
}
