import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../core/ui_icons.dart';
import 'charts.dart';
import 'common.dart';
import 'cover.dart';

/// 详情页头部：头像 / 封面 + 标题 + 标签
class DetailHero extends StatelessWidget {
  final Widget avatar;
  final String title;
  final List<Widget> tags;

  const DetailHero({
    super.key,
    required this.avatar,
    required this.title,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                    color: c.text1,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 大分数 + 星级 + 一句话排名
class BigScore extends StatelessWidget {
  final double score;
  final String rankLine;

  const BigScore({super.key, required this.score, required this.rankLine});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: fmtScore(score)),
                TextSpan(
                  text: '分',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: c.brand,
                  ),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 66,
              fontWeight: FontWeight.w900,
              height: 0.9,
              color: c.brand,
              letterSpacing: -3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScoreStars(score: score),
                const SizedBox(height: 8),
                Text(
                  rankLine,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.brand,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 详情页底部操作条
class DetailBar extends StatelessWidget {
  final String label;
  final VoidCallback onRate;
  final VoidCallback? onShare;

  const DetailBar({
    super.key,
    required this.label,
    required this.onRate,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onShare,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Center(
                child: SvgIcon(Ui.share, size: 20, color: c.text2),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(label: label, onTap: onRate),
          ),
        ],
      ),
    );
  }
}

/// 详情页滚动容器（含下拉刷新）
class DetailScroll extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> children;

  const DetailScroll({
    super.key,
    required this.onRefresh,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return RefreshIndicator(
      color: c.brand,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 28),
        children: children,
      ),
    );
  }
}
