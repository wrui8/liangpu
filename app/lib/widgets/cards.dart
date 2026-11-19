import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'charts.dart';
import 'cover.dart';
import 'remote_image.dart';

/// 首页团队评分卡：92 封面 + 信息 + 大分数
class TeamScoreCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const TeamScoreCard({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kShadowLight,
        ),
        child: Row(
          children: [
            TeamCover(
              iconKey: team.iconKey,
              color1: team.color1,
              color2: team.color2,
              short: team.short,
              width: 92,
              height: 92,
              radius: 14,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${team.category} · ${team.count} 人评分 · ${team.employeeCount} 名员工',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.text3),
                  ),
                  const SizedBox(height: 10),
                  MiniDist(dist: team.dist),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmtScore(team.score),
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: c.brand,
                    height: 1,
                    letterSpacing: -0.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '/10',
                  style: TextStyle(fontSize: 10, color: c.text3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 首页横滑热门卡
class HotCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const HotCard({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TeamCover(
              iconKey: team.iconKey,
              color1: team.color1,
              color2: team.color2,
              short: team.short,
              width: 98,
              height: 86,
              radius: 11,
            ),
            const SizedBox(height: 9),
            Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.text1,
              ),
            ),
            const SizedBox(height: 2),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: fmtScore(team.score)),
                  TextSpan(
                    text: '分',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: c.text3,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: c.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 团队页列表行
class DeptRow extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const DeptRow({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kShadowLight,
        ),
        child: Row(
          children: [
            TeamCover(
              iconKey: team.iconKey,
              color1: team.color1,
              color2: team.color2,
              short: team.short,
              width: 56,
              height: 56,
              radius: 12,
              iconRatio: 0.54,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${team.category} · ${team.count} 人评分 · ${team.employeeCount} 名员工',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.text3),
                  ),
                  const SizedBox(height: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: MiniDist(dist: team.dist, height: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: fmtScore(team.score)),
                  TextSpan(
                    text: '/10',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: c.text3,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: c.brand,
                letterSpacing: -0.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 员工网格卡（团队员工 / 需求相关员工）
class EmpCard extends StatelessWidget {
  final String name;
  final String? iconKey;
  final String color1;
  final String color2;
  final String subtitle;
  final double score;
  final VoidCallback onTap;

  const EmpCard({
    super.key,
    required this.name,
    required this.iconKey,
    required this.color1,
    required this.color2,
    required this.subtitle,
    required this.score,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kShadowLight,
        ),
        child: Column(
          children: [
            EmployeeAvatar(
              name: name,
              iconKey: iconKey,
              color1: color1,
              color2: color2,
              size: 42,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: c.text1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: c.text3),
            ),
            const SizedBox(height: 6),
            Text(
              fmtScore(score),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: c.brand,
                letterSpacing: -0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 需求卡
class NeedCard extends StatelessWidget {
  final Need need;
  final VoidCallback onTap;

  const NeedCard({super.key, required this.need, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 11),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusPill(need.status),
                const SizedBox(width: 8),
                Text(
                  need.category,
                  style: TextStyle(fontSize: 10, color: c.text3),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    need.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: c.text1,
                    ),
                  ),
                ),
                if (need.images.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RemoteImage(
                      url: need.images.first,
                      width: 58,
                      height: 58,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              need.desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: c.text2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PeopleStack(members: need.members),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    [
                      if (need.teamName != null && need.teamName!.isNotEmpty)
                        need.teamName!,
                      if (need.proposerName != null &&
                          need.proposerName!.isNotEmpty)
                        need.proposerName!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: fmtScore(need.score),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: c.brand,
                        ),
                      ),
                      TextSpan(
                        text: ' 分 · ${need.count} 人参与',
                        style: TextStyle(fontSize: 11, color: c.text3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 叠加头像组
class PeopleStack extends StatelessWidget {
  final List<NeedMember> members;
  final double size;

  const PeopleStack({super.key, required this.members, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    if (members.isEmpty) return const SizedBox.shrink();
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;
    final step = size * 0.7;
    final overlapBorder = size > 24 ? 2.0 : 2.0;

    final children = <Widget>[];
    for (var i = 0; i < shown.length; i++) {
      children.add(Positioned(
        left: i * step,
        child: Container(
          padding: EdgeInsets.all(overlapBorder),
          decoration: BoxDecoration(
            color: c.surface,
            shape: BoxShape.circle,
          ),
          child: EmployeeAvatar(
            name: shown[i].name,
            iconKey: shown[i].iconKey,
            color1: shown[i].color1,
            color2: shown[i].color2,
            size: size,
          ),
        ),
      ));
    }
    if (extra > 0) {
      children.add(Positioned(
        left: shown.length * step,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: c.line,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '+$extra',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              color: c.text3,
            ),
          ),
        ),
      ));
    }

    final lastLeft = extra > 0 ? shown.length * step : (shown.length - 1) * step;
    final lastWidth = extra > 0 ? size : size + overlapBorder * 2;
    return SizedBox(
      width: lastLeft + lastWidth,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }
}

/// 员工详情里的所属团队卡
class DeptLinkCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const DeptLinkCard({super.key, required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kShadowLight,
        ),
        child: Row(
          children: [
            TeamCover(
              iconKey: team.iconKey,
              color1: team.color1,
              color2: team.color2,
              short: team.short,
              width: 42,
              height: 42,
              radius: 11,
              iconRatio: 0.54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '查看团队评分与全部员工',
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ),
            SvgIconChevron(color: c.text3),
          ],
        ),
      ),
    );
  }
}

class SvgIconChevron extends StatelessWidget {
  final Color color;

  const SvgIconChevron({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      '›',
      style: TextStyle(fontSize: 16, color: color),
    );
  }
}
