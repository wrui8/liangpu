import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/cards.dart';
import '../widgets/charts.dart';
import '../widgets/comment_tile.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import '../widgets/detail.dart';
import '../widgets/rating_sheet.dart';
import 'employee_detail_page.dart';

class TeamDetailPage extends StatefulWidget {
  final int teamId;

  const TeamDetailPage({super.key, required this.teamId});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  TeamDetail? _detail;
  bool _loading = true;
  String? _error;
  Timer? _agentRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _agentRefresh?.cancel();
    super.dispose();
  }

  /// 评论中 @ 了 Agent 时，等后端异步生成回复后静默刷新
  void _onAgentPending() {
    _agentRefresh?.cancel();
    _agentRefresh = Timer(const Duration(seconds: 3), () {
      if (mounted) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    final app = AppScope.of(context);
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await app.api.teamDetail(widget.teamId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_detail == null) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rate({int initial = 0}) async {
    final team = _detail?.team;
    if (team == null) return;
    final action = await showRatingSheet(
      context,
      targetType: 'team',
      targetId: team.id,
      title: team.name,
      initialScore: initial,
    );
    if (action == null || !mounted) return;
    showToast(context, action.updated ? '已更新你的评分' : '评分成功');
    AppScope.of(context).refreshAggregates();
    await _load(silent: true);
  }

  Future<void> _share() async {
    final team = _detail?.team;
    if (team == null) return;
    await Clipboard.setData(
      ClipboardData(text: '良扑 · 团队「${team.name}」评分 ${fmtScore(team.score)} 分'),
    );
    if (mounted) showToast(context, '已复制分享文案');
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    final c = LpColors.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: d?.team.name ?? '团队详情',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconBtn(
              Ui.more,
              onTap: () => showToast(context, '更多功能开发中'),
            ),
          ],
        ),
      ),
      body: _loading && d == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
          : _error != null && d == null
              ? Center(
                  child: ErrorView(message: _error!, onRetry: () => _load()),
                )
              : d == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: DetailScroll(
                            onRefresh: () => _load(silent: true),
                            children: [
                              DetailHero(
                                avatar: TeamCover(
                                  iconKey: d.team.iconKey,
                                  color1: d.team.color1,
                                  color2: d.team.color2,
                                  short: d.team.short,
                                  width: 74,
                                  height: 74,
                                  radius: 20,
                                ),
                                title: d.team.name,
                                tags: [
                                  TagChip(d.team.category, red: true),
                                  const TagChip('团队评分'),
                                ],
                              ),
                              BigScore(
                                score: d.team.score,
                                rankLine:
                                    '${d.team.count} 人评分 · 超过 ${(d.team.score * 10.6).round().clamp(0, 99)}% 的团队',
                              ),
                              RateCard(
                                score: d.team.score,
                                count: d.team.count,
                                dist: d.team.dist,
                                onRate: _rate,
                                onStar: (n) => _rate(initial: n * 2),
                              ),
                              if (d.team.tags.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 14, 20, 0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final t in d.team.tags)
                                        PillTag(t),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 22, 20, 0),
                                child: SectionTitle(
                                  '团队员工',
                                  trailing: Text(
                                    '${d.employees.length} 人',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: c.text3,
                                    ),
                                  ),
                                ),
                              ),
                              if (d.employees.isEmpty)
                                Container(
                                  margin: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 22),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: kShadowLight,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '暂无下挂员工',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: c.text3,
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  child: GridView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 9,
                                      crossAxisSpacing: 9,
                                      mainAxisExtent: 128,
                                    ),
                                    children: [
                                      for (final e in d.employees)
                                        EmpCard(
                                          name: e.name,
                                          iconKey: e.iconKey,
                                          color1: e.color1,
                                          color2: e.color2,
                                          subtitle: e.title,
                                          score: e.score,
                                          onTap: () => Navigator.of(context)
                                              .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EmployeeDetailPage(
                                                employeeId: e.id,
                                              ),
                                            ),
                                          )
                                              .then((_) => _load(silent: true)),
                                        ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 22, 20, 0),
                                child: SectionTitle('亮评'),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: CommentList(
                                  comments: d.comments,
                                  onAgentPending: _onAgentPending,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DetailBar(
                          label: '我要打分',
                          onRate: _rate,
                          onShare: _share,
                        ),
                      ],
                    ),
    );
  }
}
