import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';

/// 卡片底部的迷你分布条（10 根竖条）
class MiniDist extends StatelessWidget {
  final List<double> dist;
  final double height;
  final double gap;

  const MiniDist({
    super.key,
    required this.dist,
    this.height = 20,
    this.gap = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final maxV = math.max(1.0, dist.reduce(math.max));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < dist.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: math.max(0.1, dist[i] / maxV),
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(1.5),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          c.brand,
                          Color.lerp(c.brand, const Color(0xFFFFB2B8), 0.55)!,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 详情页 10 档分布条（带百分比与分数标签）
class DistBars extends StatelessWidget {
  final List<double> dist;
  final double height;

  const DistBars({super.key, required this.dist, this.height = 108});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final maxV = math.max(1.0, dist.reduce(math.max));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < dist.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${dist[i].round()}%',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: c.text3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: math.max(0.04, dist[i] / maxV),
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3.5),
                              topRight: Radius.circular(3.5),
                              bottomLeft: Radius.circular(2),
                              bottomRight: Radius.circular(2),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                c.brand,
                                Color.lerp(
                                  c.brand,
                                  const Color(0xFFFFA0A8),
                                  0.6,
                                )!,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: c.text3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;

  _FractionClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction.clamp(0.0, 1.0), size.height);

  @override
  bool shouldReclip(_FractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

/// 五角星评分条：score 为 0-10
class ScoreStars extends StatelessWidget {
  final double score;
  final double size;
  final Color? color;
  final Color? offColor;

  const ScoreStars({
    super.key,
    required this.score,
    this.size = 15,
    this.color,
    this.offColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final base = TextStyle(
      fontSize: size,
      height: 1,
      letterSpacing: size * 0.16,
    );
    final on = base.copyWith(color: color ?? c.brand);
    final off = base.copyWith(color: offColor ?? c.line);
    final tp = TextPainter(
      text: TextSpan(text: '★★★★★', style: on),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width;
    final h = tp.height;
    final pct = (score / 10).clamp(0.0, 1.0);
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        children: [
          Text('★★★★★', style: off),
          ClipRect(
            clipper: _FractionClipper(pct),
            child: Text('★★★★★', style: on),
          ),
        ],
      ),
    );
  }
}

/// 评分趋势折线图（复刻原型 trendSVG）
class TrendChart extends StatelessWidget {
  final double score;
  final DateTime? now;

  const TrendChart({super.key, required this.score, this.now});

  static const double _w = 336;
  static const double _h = 148;

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final t = now ?? DateTime.now();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _w;
        final height = width * _h / _w;
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _TrendPainter(
              values: makeTrend(score, t),
              labels: recentMonthLabels(t),
              score: score,
              brand: c.brand,
              grid: c.chartGrid,
              text3: c.text3,
              text1: c.text1,
            ),
          ),
        );
      },
    );
  }
}

class _TrendPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double score;
  final Color brand;
  final Color grid;
  final Color text3;
  final Color text1;

  _TrendPainter({
    required this.values,
    required this.labels,
    required this.score,
    required this.brand,
    required this.grid,
    required this.text3,
    required this.text1,
  });

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w500,
    TextAlign align = TextAlign.center,
    double letterSpacing = 0,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const W = 336.0, H = 148.0, L = 26.0, R = 14.0, T = 14.0, B = 22.0;
    final sx = size.width / W;
    final sy = size.height / H;
    canvas.save();
    canvas.scale(sx, sy);

    final iw = W - L - R;
    final ih = H - T - B;
    double px(int i) => L + iw * i / (values.length - 1);
    double py(double v) => T + ih * (1 - v / 10);

    // 网格与 y 轴刻度
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final v in const [0.0, 2.0, 4.0, 6.0, 8.0, 10.0]) {
      final yy = py(v);
      canvas.drawLine(Offset(L, yy), Offset(W - R, yy), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: v.round().toString(),
          style: TextStyle(fontSize: 9, color: text3),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(L - 7 - tp.width, yy - tp.height / 2));
    }

    // 末点虚线
    final lx = px(values.length - 1);
    _dashedLine(
      canvas,
      Offset(lx, T),
      Offset(lx, H - B),
      Paint()
        ..color = grid
        ..strokeWidth = 1,
    );

    // 折线
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(px(i), py(values[i]));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 数据点（末点用星标代替）
    final dot = Paint()..color = brand;
    for (var i = 0; i < values.length - 1; i++) {
      canvas.drawCircle(Offset(px(i), py(values[i])), 2.3, dot);
    }

    final ly = py(values.last);
    _text(
      canvas,
      '★',
      Offset(lx - 8, ly - 4),
      size: 16,
      color: const Color(0xFFF5B301),
    );
    _text(
      canvas,
      fmtScore(score),
      Offset(lx - 24, ly + 14),
      size: 18,
      color: text1,
      weight: FontWeight.w900,
      letterSpacing: -0.5,
    );

    // x 轴月份
    for (var i = 0; i < labels.length && i < values.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 9, color: text3),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(px(i) - tp.width / 2, H - 12));
    }

    canvas.restore();
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 3.0, gapLen = 4.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(from + dir * d, from + dir * end, paint);
      d = end + gapLen;
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values ||
      old.score != score ||
      old.brand != brand ||
      old.grid != grid ||
      old.text1 != text1 ||
      old.text3 != text3;
}

class StatusPill extends StatelessWidget {
  final String status;

  const StatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    late final Color fg;
    late final Color bg;
    switch (status) {
      case '已完成':
        fg = isDark ? const Color(0xFF3DD7A4) : const Color(0xFF1FA97C);
        bg = isDark
            ? const Color(0x1A3DD7A4)
            : const Color(0x1A1FA97C);
        break;
      case '进行中':
      case '开发中':
        fg = isDark ? const Color(0xFFF0A050) : const Color(0xFFD97A1E);
        bg = isDark
            ? const Color(0x1AF0A050)
            : const Color(0x1AD97A1E);
        break;
      default:
        fg = isDark ? const Color(0xFFFF5A66) : const Color(0xFFE0202D);
        bg = isDark
            ? const Color(0x29F23441)
            : const Color(0x14E0202D);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// 良扑评分卡：趋势 / 分布切换 + 立即评分 + 五星快评
class RateCard extends StatefulWidget {
  final double score;
  final int count;
  final List<double> dist;
  final VoidCallback? onRate;
  final ValueChanged<int>? onStar;

  const RateCard({
    super.key,
    required this.score,
    required this.count,
    required this.dist,
    this.onRate,
    this.onStar,
  });

  @override
  State<RateCard> createState() => _RateCardState();
}

class _RateCardState extends State<RateCard> {
  bool _trend = true;

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kShadowLight,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '良',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '良扑评分',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: c.brand,
                ),
              ),
              const Spacer(),
              _tab('趋势', _trend, () => setState(() => _trend = true)),
              const SizedBox(width: 14),
              _tab('分布', !_trend, () => setState(() => _trend = false)),
            ],
          ),
          const SizedBox(height: 8),
          if (_trend)
            TrendChart(score: widget.score)
          else
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '共 ${widget.count} 人评分',
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                  const SizedBox(height: 8),
                  DistBars(dist: widget.dist),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onRate,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '立即评分',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: c.text2,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => widget.onStar?.call(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
                    child: Text(
                      '★',
                      style: TextStyle(
                        fontSize: 22,
                        height: 1,
                        color: c.starOff,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool on, VoidCallback onTap) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: on ? FontWeight.w800 : FontWeight.w500,
          color: on ? c.text1 : c.text3,
        ),
      ),
    );
  }
}
