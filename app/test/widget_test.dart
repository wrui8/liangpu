import 'package:flutter_test/flutter_test.dart';
import 'package:liangpu_app/core/theme.dart';

void main() {
  test('评分格式化与趋势数据', () {
    expect(fmtScore(8.7), '8.7');
    expect(fmtScore(9), '9.0');

    final trend = makeTrend(9.9, DateTime(2026, 11, 18));
    expect(trend.length, 6);
    expect(trend.last, 9.9);
    expect(trend.every((v) => v >= 1 && v <= 10), isTrue);

    final labels = recentMonthLabels(DateTime(2026, 11, 18));
    expect(labels.first, '6月');
    expect(labels.last, '11月');
  });
}
