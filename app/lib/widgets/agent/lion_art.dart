import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// 手绘小狮子（矢量绘制，非图片）。
///
/// 用多层渐变堆出立体感：鬃毛分前后两圈、脸部球面高光、口鼻与眼睛的高光点，
/// 底部带柔和投影。所有坐标基于 100×100 的设计稿，按尺寸等比缩放。
class LionArt extends StatelessWidget {
  /// 0 = 睁眼，1 = 闭眼（由外部眨眼动画驱动）
  final double blink;

  const LionArt({super.key, this.blink = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LionPainter(blink: blink.clamp(0.0, 1.0)),
      size: Size.infinite,
    );
  }
}

class _LionPainter extends CustomPainter {
  final double blink;

  _LionPainter({required this.blink});

  static const Color _maneDark = Color(0xFFC9760F);
  static const Color _maneMid = Color(0xFFEFA025);
  static const Color _maneLight = Color(0xFFFFCE4F);

  static const Color _faceLight = Color(0xFFFFF3CE);
  static const Color _faceMid = Color(0xFFFFD98A);
  static const Color _faceEdge = Color(0xFFE9A23B);

  static const Color _earOuter = Color(0xFFE7A03A);
  static const Color _earInner = Color(0xFFB9722A);

  static const Color _muzzleLight = Color(0xFFFFF9EC);
  static const Color _muzzleShade = Color(0xFFF1DCB8);

  static const Color _ink = Color(0xFF5C3823);
  static const Color _eye = Color(0xFF33221A);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);

    _shadow(canvas);
    _mane(canvas, back: true);
    _mane(canvas, back: false);
    _ears(canvas);
    _faceShadow(canvas);
    _face(canvas);
    _muzzle(canvas);
    _blush(canvas);
    _nose(canvas);
    _mouth(canvas);
    _eyes(canvas);

    canvas.restore();
  }

  // ---------- 投影 ----------
  void _shadow(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF1A1208).withValues(alpha: 0.20)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 91),
        width: 52,
        height: 11,
      ),
      paint,
    );
  }

  // ---------- 鬃毛：两圈花瓣，前亮后暗形成纵深 ----------
  void _mane(Canvas canvas, {required bool back}) {
    const center = Offset(50, 52);
    const count = 12;
    final step = (math.pi * 2) / count;

    for (var i = 0; i < count; i++) {
      final a = i * step + (back ? 0 : step / 2);

      // 后圈：更大更深，微微外扩
      final rx = back ? 10.5 : 7.6;
      final ry = back ? 17.5 : 13.2;
      final radius = back ? 27.0 : 26.0;
      final dir = Offset(math.cos(a), math.sin(a));
      final petalCenter = center + dir * radius;

      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      // 局部 -y 指向外圈
      canvas.rotate(a + math.pi / 2);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: rx * 2,
        height: ry * 2,
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: back
              ? [_maneMid, _maneDark]
              : [_maneLight, _maneMid],
        ).createShader(rect);
      canvas.drawOval(rect, paint);

      // 花瓣顶部受光：每根鬃毛都像个圆滚滚的小团子
      final tipRect = Rect.fromCenter(
        center: Offset(0, -ry * 0.34),
        width: rx * 1.35,
        height: ry * 1.05,
      );
      canvas.drawOval(
        tipRect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.25, -0.3),
            colors: [
              Colors.white.withValues(alpha: back ? 0.16 : 0.26),
              const Color(0x00FFFFFF),
            ],
          ).createShader(tipRect),
      );

      // 花瓣根部一道更深的压暗，增加叠压层次
      final rootRect = Rect.fromCenter(
        center: Offset(0, ry * 0.62),
        width: rx * 1.5,
        height: ry * 0.9,
      );
      final rootPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            (back ? _maneDark : _maneMid).withValues(alpha: 0.55),
            const Color(0x00000000),
          ],
        ).createShader(rootRect);
      canvas.drawOval(rootRect, rootPaint);

      canvas.restore();
    }
  }

  // ---------- 耳朵（压在鬃毛之上、脸之下，左右上角各一个） ----------
  void _ears(Canvas canvas) {
    for (final dx in [-15.0, 15.0]) {
      final c = Offset(50 + dx, 32.5);
      final outer = Rect.fromCenter(center: c, width: 17.5, height: 17.5);
      final fill = Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.4),
          colors: [_faceMid, _earOuter],
        ).createShader(outer);
      canvas.drawOval(outer, fill);
      canvas.drawOval(
        outer,
        Paint()
          ..color = _maneDark.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(0, 0.8), width: 6, height: 7),
        Paint()..color = _earInner,
      );
    }
  }

  /// 脸压在鬃毛上的一圈环境阴影，让头「浮」在鬃毛前面
  void _faceShadow(Canvas canvas) {
    canvas.drawCircle(
      const Offset(50, 54),
      20.8,
      Paint()
        ..color = const Color(0xFF7A4A16).withValues(alpha: 0.22)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.2),
    );
  }

  // ---------- 脸：球面渐变 + 高光 ----------
  void _face(Canvas canvas) {
    const c = Offset(50, 52);
    const r = 21.0;
    final faceRect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          radius: 1.15,
          colors: [_faceLight, _faceMid, _faceEdge],
          stops: [0.0, 0.58, 1.0],
        ).createShader(faceRect),
    );

    // 背光侧边缘压暗，让脸从「平面圆」变成「球」
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.45, -0.5),
          radius: 1.05,
          colors: [
            Color(0x00000000),
            Color(0x00000000),
            Color(0x437A4A16),
          ],
          stops: [0.0, 0.72, 1.0],
        ).createShader(faceRect),
    );

    // 顶部受光弧线
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 1.2),
      math.pi * 1.08,
      math.pi * 0.72,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // 底部反光（让下巴有体积）
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 2.4),
      math.pi * 0.18,
      math.pi * 0.5,
      false,
      Paint()
        ..color = const Color(0xFFFFE9B8).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  // ---------- 口鼻 ----------
  void _muzzle(Canvas canvas) {
    for (final dx in [-7.2, 7.2]) {
      final rect = Rect.fromCenter(
        center: Offset(50 + dx, 63),
        width: 18,
        height: 15,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.2, -0.55),
            colors: [_muzzleLight, _muzzleShade],
          ).createShader(rect),
      );
    }
  }

  /// 腮红：两团柔和的暖色，让脸有肉感
  void _blush(Canvas canvas) {
    for (final dx in [-13.0, 13.0]) {
      final rect = Rect.fromCenter(
        center: Offset(50 + dx, 59.5),
        width: 11,
        height: 7,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x66FF8F5C), Color(0x00FF8F5C)],
          ).createShader(rect),
      );
    }
  }

  void _nose(Canvas canvas) {
    final p = Path()
      ..moveTo(45.2, 55.4)
      ..lineTo(54.8, 55.4)
      ..quadraticBezierTo(56.2, 55.4, 55.5, 56.8)
      ..lineTo(52.3, 61.4)
      ..quadraticBezierTo(50.0, 63.7, 47.7, 61.4)
      ..lineTo(44.5, 56.8)
      ..quadraticBezierTo(43.8, 55.4, 45.2, 55.4)
      ..close();

    final rect = p.getBounds();
    canvas.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E4E32), Color(0xFF4E2E1C)],
        ).createShader(rect),
    );
    // 鼻尖高光
    canvas.drawOval(
      Rect.fromCenter(center: Offset(48.6, 57.3), width: 3.6, height: 2.2),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  void _mouth(Canvas canvas) {
    final paint = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final p = Path()
      ..moveTo(50, 61.6)
      ..lineTo(50, 64.2)
      ..moveTo(50, 64.2)
      ..quadraticBezierTo(46.6, 67.4, 44.2, 65.2)
      ..moveTo(50, 64.2)
      ..quadraticBezierTo(53.4, 67.4, 55.8, 65.2);
    canvas.drawPath(p, paint);
  }

  // ---------- 眼睛：高光点是立体感的关键 ----------
  void _eyes(Canvas canvas) {
    final openAmount = (1.0 - blink).clamp(0.0, 1.0);
    final ry = 5.2 * openAmount + 0.4;

    for (final dx in [-8.6, 8.6]) {
      final c = Offset(50 + dx, 49.4);

      if (openAmount < 0.14) {
        // 闭眼：一条下弯的弧线
        canvas.drawArc(
          Rect.fromCenter(center: c + const Offset(0, -1.2), width: 9.6, height: 7),
          math.pi * 0.12,
          math.pi * 0.76,
          false,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }

      final rect = Rect.fromCenter(center: c, width: 9.4, height: ry * 2);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF463026), _eye],
          ).createShader(rect),
      );

      // 主高光（左上）+ 次高光（右下）
      canvas.drawCircle(
        c + Offset(-1.7, -1.5),
        1.9 * openAmount.clamp(0.0, 1.0),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        c + Offset(1.5, 1.6),
        0.85 * openAmount,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LionPainter old) => old.blink != blink;
}
