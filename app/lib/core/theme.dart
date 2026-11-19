import 'package:material_ui/material_ui.dart';

/// 良扑设计 token，对齐 docs/prototype 原型（品牌红 + 双主题）。
class LpColors extends ThemeExtension<LpColors> {
  final Color brand;
  final Color brandHover;
  final Color brandSoft;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color text1;
  final Color text2;
  final Color text3;
  final Color line;
  final Color chartGrid;
  final Color starOff;

  const LpColors({
    required this.brand,
    required this.brandHover,
    required this.brandSoft,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.text1,
    required this.text2,
    required this.text3,
    required this.line,
    required this.chartGrid,
    required this.starOff,
  });

  static const light = LpColors(
    brand: Color(0xFFE0202D),
    brandHover: Color(0xFFC81522),
    brandSoft: Color(0x14E0202D),
    bg: Color(0xFFF4F5F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF7F8FA),
    text1: Color(0xFF14161A),
    text2: Color(0xFF5F6670),
    text3: Color(0xFF9AA1AA),
    line: Color(0xFFECEEF1),
    chartGrid: Color(0xFFEDEFF2),
    starOff: Color(0xFFC9CFD6),
  );

  static const dark = LpColors(
    brand: Color(0xFFF23441),
    brandHover: Color(0xFFFF4A55),
    brandSoft: Color(0x24F23441),
    bg: Color(0xFF0E0F11),
    surface: Color(0xFF17181C),
    surface2: Color(0xFF1E2025),
    text1: Color(0xFFF0F1F3),
    text2: Color(0xFF9AA1AA),
    text3: Color(0xFF6A717B),
    line: Color(0xFF272A30),
    chartGrid: Color(0xFF262A30),
    starOff: Color(0xFF3B4048),
  );

  static LpColors of(BuildContext context) =>
      Theme.of(context).extension<LpColors>() ?? light;

  @override
  LpColors copyWith({
    Color? brand,
    Color? brandHover,
    Color? brandSoft,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? text1,
    Color? text2,
    Color? text3,
    Color? line,
    Color? chartGrid,
    Color? starOff,
  }) {
    return LpColors(
      brand: brand ?? this.brand,
      brandHover: brandHover ?? this.brandHover,
      brandSoft: brandSoft ?? this.brandSoft,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      text1: text1 ?? this.text1,
      text2: text2 ?? this.text2,
      text3: text3 ?? this.text3,
      line: line ?? this.line,
      chartGrid: chartGrid ?? this.chartGrid,
      starOff: starOff ?? this.starOff,
    );
  }

  @override
  LpColors lerp(ThemeExtension<LpColors>? other, double t) {
    if (other is! LpColors) return this;
    return LpColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandHover: Color.lerp(brandHover, other.brandHover, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      text1: Color.lerp(text1, other.text1, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      text3: Color.lerp(text3, other.text3, t)!,
      line: Color.lerp(line, other.line, t)!,
      chartGrid: Color.lerp(chartGrid, other.chartGrid, t)!,
      starOff: Color.lerp(starOff, other.starOff, t)!,
    );
  }
}

ThemeData buildLpTheme(bool dark) {
  final c = dark ? LpColors.dark : LpColors.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: c.brand,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: c.brand,
    surface: c.surface,
    onSurface: c.text1,
    outline: c.line,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: [c],
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.brand,
      selectionColor: c.brandSoft,
      selectionHandleColor: c.brand,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xF016181C),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
  );
}

const kShadow = BoxShadow(
  color: Color(0x0F14161A),
  blurRadius: 12,
  offset: Offset(0, 2),
);

List<BoxShadow> get kShadowLight => const [
      BoxShadow(color: Color(0x0F14161A), blurRadius: 12, offset: Offset(0, 2)),
    ];

/// 数字格式化：8.7 -> "8.7"，9 -> "9.0"
String fmtScore(num v) => v.toDouble().toStringAsFixed(1);

/// 评分历史趋势（与原型 makeTrend 一致）
List<double> makeTrend(double score, DateTime now) {
  const offsets = [-0.6, -0.2, -0.5, -0.3, -0.1, 0];
  return offsets.map((o) {
    final v = (score + o).clamp(1.0, 10.0);
    return (v * 10).round() / 10;
  }).toList();
}

/// 最近 6 个月标签，如 6月 … 11月
List<String> recentMonthLabels(DateTime now) {
  const names = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
  final out = <String>[];
  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i);
    out.add(names[m.month - 1]);
  }
  return out;
}
