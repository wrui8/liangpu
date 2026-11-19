import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';

Color hexColor(String hex, {Color fallback = const Color(0xFF8E9BFF)}) {
  var h = hex.trim();
  if (h.isEmpty) return fallback;
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

class SvgIcon extends StatelessWidget {
  final String svg;
  final double size;
  final Color? color;

  const SvgIcon(this.svg, {super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter:
          color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

/// 上下轻微浮动的图标（团队封面 / 人像）
class Floating extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  const Floating({
    super.key,
    required this.child,
    this.amplitude = 2,
    this.period = const Duration(milliseconds: 2750),
  });

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat(reverse: true);
  late final Animation<double> _a = Tween<double>(
    begin: 0,
    end: -widget.amplitude,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _a.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// 团队封面：渐变底 + 白色语义图标 + 装饰
class TeamCover extends StatelessWidget {
  final String? iconKey;
  final String color1;
  final String color2;
  final String short;
  final double width;
  final double height;
  final double radius;
  final bool animate;
  final double iconRatio;

  const TeamCover({
    super.key,
    required this.iconKey,
    required this.color1,
    required this.color2,
    required this.short,
    required this.width,
    required this.height,
    this.radius = 14,
    this.animate = true,
    this.iconRatio = 0.46,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final svg = app.iconSvg(iconKey);
    final c1 = hexColor(color1);
    final c2 = hexColor(color2);
    final iconSize = height * iconRatio;

    Widget icon = svg != null
        ? SvgIcon(svg, size: iconSize, color: Colors.white)
        : Text(
            short,
            style: TextStyle(
              color: Colors.white,
              fontSize: iconSize * 0.86,
              fontWeight: FontWeight.w800,
            ),
          );
    if (animate) {
      icon = Floating(amplitude: height * 0.03, child: icon);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c1, c2],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -width * 0.3,
              bottom: -width * 0.44,
              child: Container(
                width: width * 0.96,
                height: width * 0.96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.17),
                ),
              ),
            ),
            Positioned(
              left: width * 0.13,
              top: height * 0.13,
              child: Container(
                width: width * 0.07,
                height: width * 0.07,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            Center(child: icon),
          ],
        ),
      ),
    );
  }
}

/// 员工头像：有图标时显示白色徽章图标，否则姓名首字
class EmployeeAvatar extends StatelessWidget {
  final String name;
  final String? iconKey;
  final String color1;
  final String color2;
  final double size;

  const EmployeeAvatar({
    super.key,
    required this.name,
    required this.iconKey,
    required this.color1,
    required this.color2,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final svg = app.iconSvg(iconKey);
    final c1 = hexColor(color1);
    final c2 = hexColor(color2);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
      alignment: Alignment.center,
      child: svg != null
          ? SvgIcon(svg, size: size * 0.56, color: Colors.white)
          : Text(
              name.isEmpty ? '?' : name.characters.first,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// 用户头像（人像池 SVG），带轻微浮动动画
class UserAvatar extends StatelessWidget {
  final String? svg;
  final String fallbackName;
  final double size;
  final bool animate;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    super.key,
    required this.svg,
    required this.fallbackName,
    this.size = 40,
    this.animate = true,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    Widget inner;
    if (svg != null && svg!.isNotEmpty) {
      inner = ClipOval(
        child: SvgPicture.string(svg!, width: size, height: size),
      );
    } else {
      inner = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              c.brand.withValues(alpha: 0.7),
              c.brand,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          fallbackName.isEmpty ? '良' : fallbackName.characters.first,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    if (animate) {
      inner = Floating(amplitude: size * 0.03, child: inner);
    }
    if (borderWidth <= 0) return inner;
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? c.surface,
          width: borderWidth,
        ),
      ),
      child: inner,
    );
  }
}

/// 通用首字头像（评论 / 需求占位）
class LetterAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color color1;
  final Color color2;

  const LetterAvatar({
    super.key,
    required this.text,
    required this.color1,
    required this.color2,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? '?' : text.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
