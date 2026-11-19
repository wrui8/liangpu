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
import 'need_detail_page.dart';
import 'team_detail_page.dart';

class EmployeeDetailPage extends StatefulWidget {
  final int employeeId;

  const EmployeeDetailPage({super.key, required this.employeeId});

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  EmployeeDetail? _detail;
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
      final d = await app.api.employeeDetail(widget.employeeId);
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
    final emp = _detail?.employee;
    if (emp == null) return;
    final action = await showRatingSheet(
      context,
      targetType: 'employee',
      targetId: emp.id,
      title: emp.name,
      initialScore: initial,
    );
    if (action == null || !mounted) return;
    showToast(context, action.updated ? '已更新你的评分' : '评分成功');
    AppScope.of(context).refreshAggregates();
    await _load(silent: true);
  }

  Future<void> _share() async {
    final emp = _detail?.employee;
    if (emp == null) return;
    await Clipboard.setData(
      ClipboardData(text: '良扑 · ${emp.name} 同事评分 ${fmtScore(emp.score)} 分'),
    );
    if (mounted) showToast(context, '已复制分享文案');
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: d?.employee.name ?? '员工详情',
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
                                avatar: EmployeeAvatar(
                                  name: d.employee.name,
                                  iconKey: d.employee.iconKey,
                                  color1: d.employee.color1,
                                  color2: d.employee.color2,
                                  size: 74,
                                ),
                                title: d.employee.name,
                                tags: [
                                  if (d.employee.title.isNotEmpty)
                                    TagChip(d.employee.title, red: true),
                                  TagChip(d.team.name),
                                ],
                              ),
                              BigScore(
                                score: d.employee.score,
                                rankLine:
                                    '${d.employee.count} 人评分 · 超过 ${(d.employee.score * 10.6).round().clamp(0, 99)}% 的同事',
                              ),
                              RateCard(
                                score: d.employee.score,
                                count: d.employee.count,
                                dist: d.employee.dist,
                                onRate: _rate,
                                onStar: (n) => _rate(initial: n * 2),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 22, 20, 0),
                                child: const SectionTitle('所属团队'),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: DeptLinkCard(
                                  team: d.team,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TeamDetailPage(
                                        teamId: d.team.id,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (d.needScores.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 22, 20, 0),
                                  child: SectionTitle(
                                    '在需求中的表现',
                                    trailing: Text(
                                      '不计入全局分',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: LpColors.of(context).text3,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  child: Column(
                                    children: [
                                      for (final s in d.needScores)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 9),
                                          child: _NeedScoreRow(
                                            item: s,
                                            onTap: () => Navigator.of(context)
                                                .push(
                                              MaterialPageRoute(
                                                builder: (_) => NeedDetailPage(
                                                  needId: s.needId,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
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

/// 员工在某需求中的表现分行：需求标题、状态、平均分、人数与我的评分
class _NeedScoreRow extends StatelessWidget {
  final NeedMemberScore item;
  final VoidCallback onTap;

  const _NeedScoreRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${item.status} · ${item.count} 人评分'
                    '${item.myScore != null ? ' · 我打了 ${item.myScore}' : ''}',
                    style: TextStyle(fontSize: 11.5, color: c.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              fmtScore(item.score),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: c.brand,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 2),
            SvgIcon(Ui.chevronRight, size: 14, color: c.text3),
          ],
        ),
      ),
    );
  }
}
