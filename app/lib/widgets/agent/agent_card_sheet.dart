import 'package:material_ui/material_ui.dart';

import '../../core/agent_models.dart';
import '../../core/navigator.dart';
import '../../core/state.dart';
import '../../core/theme.dart';
import 'agent_avatar.dart';
import 'agent_lion.dart';

/// Agent 名片：评论区点头像、面板头像都打开它。
/// 名称 / 介绍 / 快捷指令全部来自服务端 meta，管理端修改后自动同步。
///
/// 悬浮球与面板挂在 Navigator 之上，必须用根 Navigator 的 Overlay 打开弹层。
Future<void> showAgentCard(
  BuildContext context,
  AgentProfile agent, {
  bool demo = false,
}) async {
  final app = AppScope.of(context);
  final host =
      rootNavigatorKey.currentState?.overlay?.context ?? context;
  /* 卡片在 Navigator 的 Overlay 里，会盖在页面之上；
     先把聊天面板收起、悬浮球隐藏，避免与卡片层级打架 */
  app.agentUi.beginCard();
  try {
    await showModalBottomSheet<void>(
      context: host,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (ctx) {
      final c = LpColors.of(ctx);
      /* 名片打开期间若 meta 轮询更新（改名/换形象），实时跟着变 */
      final live =
          AppScope.of(ctx).agentMeta?.byUserId(agent.userId) ?? agent;

      void interact({String? prefill}) {
        Navigator.of(ctx).pop();
        Future<void>.delayed(const Duration(milliseconds: 80), () {
          app.openAgentPanel(prefill: prefill);
        });
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 28,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2, bottom: 12),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        kAgentGold.withValues(alpha: 0.2),
                        c.surface,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      if ((live.avatarUrl ?? '').isNotEmpty)
                        AgentAvatar(agent: live, size: 64, ring: true)
                      else
                        AnimatedLion(size: 64),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              live.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: c.text1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 5,
                              children: [
                                const AgentBadge(),
                                if (demo) _Tag('演示模式', c),
                                if (!live.canComment) _Tag('评论区未开放', c),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '✕',
                            style: TextStyle(fontSize: 15, color: c.text2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  live.intro.isEmpty ? '这个助手还没有填写介绍。' : live.intro,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.75,
                    color: c.text1,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const _Cap('查评分'),
                    const _Cap('看需求'),
                    const _Cap('分析得分'),
                    if (live.canComment) const _Cap('评论区回复'),
                  ],
                ),
                if (live.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    '你可以问我',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.text3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final s in live.suggestions)
                    GestureDetector(
                      onTap: () => interact(prefill: s),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
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
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.text1,
                                ),
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
                if (demo) ...[
                  const SizedBox(height: 10),
                  Text(
                    '当前为前端演示模式，名称、形象与介绍以后端下发为准。',
                    style: TextStyle(fontSize: 10.5, color: c.text3),
                  ),
                ],
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => interact(),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD75E), kAgentGold],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kAgentGold.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🦁', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 7),
                        const Text(
                          '互动',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF3A2B00),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  } finally {
    app.agentUi.endCard();
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final LpColors c;

  const _Tag(this.text, this.c);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: c.text3,
        ),
      ),
    );
  }
}

class _Cap extends StatelessWidget {
  final String text;

  const _Cap(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kAgentGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kAgentGold.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: agentGoldText(context),
        ),
      ),
    );
  }
}
