import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../core/agent_models.dart';
import '../../core/state.dart';
import 'agent_lion.dart';

/// Agent 品牌色：沿用公司 logo 的黄色，和 App 主品牌红形成点缀对比。
const Color kAgentGold = Color(0xFFF4C430);
const Color kAgentGoldDeep = Color(0xFF8A6A00);

Color agentGoldText(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFDE7A)
        : kAgentGoldDeep;

/// Agent 头像：管理端上传的图片优先，否则用 emoji（默认小狮子）兜底。
class AgentAvatar extends StatelessWidget {
  final AgentProfile? agent;
  final String? fallbackName;
  final double size;
  final bool ring;

  const AgentAvatar({
    super.key,
    this.agent,
    this.fallbackName,
    this.size = 40,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final profile = agent ?? app.agentMeta?.primary;
    final emoji = (profile?.avatarEmoji.isNotEmpty ?? false)
        ? profile!.avatarEmoji
        : '🦁';
    final url = profile?.avatarUrl;

    // 未上传头像：直接展示小狮子主图，不加圆形底板/描边，让角色本身成为形象
    if (url == null || url.isEmpty) {
      return LionImage(size: size, fallbackEmoji: emoji);
    }

    // 管理端上传了头像才做圆形裁切
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE58A), kAgentGold],
        ),
        border: ring
            ? Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2C31)
                    : Colors.white,
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: FutureBuilder<Uint8List>(
              future: app.api.imageBytes(url),
              builder: (context, snap) {
                if (snap.hasData) {
                  return Image.memory(
                    snap.data!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  );
                }
                return LionImage(size: size, fallbackEmoji: emoji);
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 评论昵称旁的「AI 助手」小徽标
class AgentBadge extends StatelessWidget {
  final String text;

  const AgentBadge({super.key, this.text = 'AI 助手'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: kAgentGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: kAgentGold.withValues(alpha: 0.32)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1.2,
          color: agentGoldText(context),
        ),
      ),
    );
  }
}

/// 「小狮正在输入…」提示
class AgentTypingLine extends StatelessWidget {
  final AgentProfile? agent;
  final String name;
  final double avatarSize;

  const AgentTypingLine({
    super.key,
    this.agent,
    required this.name,
    this.avatarSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AgentAvatar(agent: agent, size: avatarSize),
          const SizedBox(width: 8),
          Text(
            '$name 正在输入…',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: agentGoldText(context),
            ),
          ),
        ],
      ),
    );
  }
}
