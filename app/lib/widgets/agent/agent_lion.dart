import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'lion_art.dart';

/// 小狮子形象：矢量绘制（[LionArt]），不再使用位图。
///
/// 保留这个类是为了让各处的调用方（头像、评论区、面板空态）保持统一入口。
class LionImage extends StatelessWidget {
  final double size;

  /// 历史参数：早期用 emoji 兜底位图加载失败，现在图案为代码绘制，不再使用。
  final String fallbackEmoji;

  /// 为 true 时按圆形裁切（评论区等圆形头像场景）。
  final bool circle;

  /// 历史参数：位图时代的填充方式，矢量绘制下忽略。
  final BoxFit fit;

  const LionImage({
    super.key,
    required this.size,
    this.fallbackEmoji = '🦁',
    this.circle = false,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final art = SizedBox(
      width: size,
      height: size,
      child: const LionArt(),
    );
    return circle ? ClipOval(child: art) : art;
  }
}

/// 会动的小狮子：悬浮上下的呼吸、轻微摆头、周期性眨眼，
/// 眨眼时眼睛先闭、身体再贴地挤压回弹；思考/回复时呼吸加快并伴随金色光晕脉动。
class AnimatedLion extends StatefulWidget {
  final double size;
  final bool thinking;
  final bool glow;
  final String fallbackEmoji;

  const AnimatedLion({
    super.key,
    required this.size,
    this.thinking = false,
    this.glow = true,
    this.fallbackEmoji = '🦁',
  });

  @override
  State<AnimatedLion> createState() => _AnimatedLionState();
}

class _AnimatedLionState extends State<AnimatedLion>
    with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  /// 5.2 秒一轮：大部分时间保持原样，末尾快速眨一下再弹回。
  late final AnimationController _blink = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  late final Animation<double> _squash = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 84),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: 0.86)
          .chain(CurveTween(curve: Curves.easeIn)),
      weight: 4,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(0.86), weight: 2),
    TweenSequenceItem(
      tween: Tween<double>(begin: 0.86, end: 1)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 10,
    ),
  ]).animate(_blink);

  @override
  void dispose() {
    _float.dispose();
    _breathe.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_float, _breathe, _blink]),
        builder: (context, child) {
          final t = _float.value * 2 * math.pi;
          final dy = math.sin(t) * size * 0.05;
          final tilt = math.sin(t + 0.7) * 0.045;

          // 呼吸：思考时幅度更大、节奏更快
          final breathAmp = widget.thinking ? 0.065 : 0.032;
          final breathe = 1 + breathAmp * _breathe.value;

          // 眨眼挤压：纵向压扁、横向略胖；同时把眼睛闭上
          final sq = _squash.value;
          final sx = breathe * (1 + (1 - sq) * 0.7);
          final sy = breathe * sq;
          final blink = ((1 - sq) / 0.14).clamp(0.0, 1.0);

          Widget content = Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scaleX: sx,
                scaleY: sy,
                alignment: Alignment.bottomCenter,
                child: LionArt(blink: blink),
              ),
            ),
          );

          if (widget.glow) {
            final pulse = 0.5 + 0.5 * _breathe.value;
            final aura = size * (widget.thinking ? 0.78 : 0.68);
            final glowAlpha =
                (widget.thinking ? 0.30 : 0.16) * (0.55 + 0.45 * pulse);
            content = Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: size * 0.02 + dy,
                  child: Container(
                    width: aura,
                    height: aura * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(aura),
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFF4C430)
                              .withValues(alpha: glowAlpha),
                          const Color(0xFFF4C430).withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                content,
              ],
            );
          }

          return Center(child: content);
        },
      ),
    );
  }
}
