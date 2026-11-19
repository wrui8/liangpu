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
import '../widgets/detail.dart';
import '../widgets/rating_sheet.dart';
import '../widgets/remote_image.dart';
import 'employee_detail_page.dart';
import 'need_composer_page.dart';

class NeedDetailPage extends StatefulWidget {
  final int needId;

  const NeedDetailPage({super.key, required this.needId});

  @override
  State<NeedDetailPage> createState() => _NeedDetailPageState();
}

class _NeedDetailPageState extends State<NeedDetailPage> {
  NeedDetail? _detail;
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
      final d = await app.api.needDetail(widget.needId);
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
    final need = _detail?.need;
    if (need == null) return;
    final action = await showRatingSheet(
      context,
      targetType: 'need',
      targetId: need.id,
      title: need.title,
      initialScore: initial,
    );
    if (action == null || !mounted) return;
    showToast(context, action.updated ? '已更新你的支持' : '支持成功');
    AppScope.of(context).refreshAggregates();
    await _load(silent: true);
  }

  /// 更多菜单：发布者本人（或管理员）可编辑、删除
  Future<void> _more() async {
    final app = AppScope.of(context);
    final need = _detail?.need;
    if (need == null) return;
    final me = app.user;
    final canEdit = me != null &&
        (me.id == need.proposerId || me.role == 'admin');
    if (!canEdit) {
      showToast(context, '只有发布者可以编辑或删除该需求');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = LpColors.of(ctx);
        Widget item(String key, String label, {Color? color}) => InkWell(
              onTap: () => Navigator.of(ctx).pop(key),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14.5, color: color ?? c.text1),
                ),
              ),
            );
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              item('edit', '编辑需求'),
              Divider(height: 1, color: c.line),
              item('delete', '删除需求', color: c.brand),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => NeedComposerPage(initial: _detail!.need),
        ),
      );
      if (saved == true && mounted) {
        AppScope.of(context).loadNeeds(force: true);
        _load(silent: true);
      }
    } else if (action == 'delete') {
      await _delete();
    }
  }

  Future<void> _delete() async {
    final c = LpColors.of(context);
    final need = _detail?.need;
    if (need == null) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除需求'),
        content: const Text('删除后不可恢复，相关评分、评论与配图也会一起清理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('删除', style: TextStyle(color: c.brand)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await AppScope.of(context).api.deleteNeed(need.id);
      if (!mounted) return;
      AppScope.of(context).loadNeeds(force: true);
      showToast(context, '需求已删除');
      Navigator.of(context).maybePop();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  /// 成员卡片：查看主页，或在本需求维度给该成员打分（不影响全局分与团队分）
  Future<void> _openMember(NeedMember m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = LpColors.of(ctx);
        Widget item(String key, String label) => InkWell(
              onTap: () => Navigator.of(ctx).pop(key),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14.5, color: c.text1),
                ),
              ),
            );
        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Text(
                m.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.text1,
                ),
              ),
              const SizedBox(height: 6),
              item('profile', '查看员工主页'),
              Divider(height: 1, color: c.line),
              item('rate', '在本需求中评分'),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    if (action == 'profile') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmployeeDetailPage(employeeId: m.employeeId),
        ),
      );
      if (mounted) _load(silent: true);
    } else if (action == 'rate') {
      await _rateMember(m);
    }
  }

  Future<void> _rateMember(NeedMember m) async {
    final need = _detail?.need;
    if (need == null) return;
    final action = await showRatingSheet(
      context,
      targetType: 'employee',
      targetId: m.employeeId,
      title: m.name,
      initialScore: m.myScore ?? 0,
      scopeType: 'need',
      scopeId: need.id,
    );
    if (action == null || !mounted) return;
    showToast(context, action.updated ? '已更新你在本需求中的评分' : '评分成功');
    await _load(silent: true);
  }

  Future<void> _share() async {
    final need = _detail?.need;
    if (need == null) return;
    await Clipboard.setData(
      ClipboardData(text: '良扑 · 需求「${need.title}」支持度 ${fmtScore(need.score)} 分'),
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
          title: '需求详情',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconBtn(Ui.more, onTap: _more),
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
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 10, 20, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        StatusPill(d.need.status),
                                        const SizedBox(width: 8),
                                        TagChip(d.need.category),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      d.need.title,
                                      style: TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.w800,
                                        height: 1.42,
                                        color: c.text1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      [
                                        if (d.need.teamName != null &&
                                            d.need.teamName!.isNotEmpty)
                                          d.need.teamName!,
                                        if (d.need.proposerName != null &&
                                            d.need.proposerName!.isNotEmpty)
                                          d.need.proposerName!,
                                        if (timeAgo(d.need.createdAt).isNotEmpty)
                                          timeAgo(d.need.createdAt),
                                      ].join(' · '),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: c.text3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              BigScore(
                                score: d.need.score,
                                rankLine:
                                    '${d.need.count} 人支持 · 全员打分决定优先级',
                              ),
                              RateCard(
                                score: d.need.score,
                                count: d.need.count,
                                dist: d.need.dist,
                                onRate: _rate,
                                onStar: (n) => _rate(initial: n * 2),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 22, 20, 0),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SectionTitle('需求描述'),
                                    const SizedBox(height: 10),
                                    Text(
                                      d.need.desc,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.78,
                                        color: c.text1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (d.need.images.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 14, 20, 0),
                                  child: _NeedImages(images: d.need.images),
                                ),
                              if (d.need.tags.isNotEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 14, 20, 0),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final t in d.need.tags)
                                        PillTag(t),
                                    ],
                                  ),
                                ),
                              if (d.need.members.isNotEmpty) ...[
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 22, 20, 0),
                                  child: SectionTitle(
                                    '相关员工',
                                    trailing: Text(
                                      '${d.need.members.length} 人 · 本需求表现分',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: c.text3,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                                      for (final m in d.need.members)
                                        EmpCard(
                                          name: m.name,
                                          iconKey: m.iconKey,
                                          color1: m.color1,
                                          color2: m.color2,
                                          subtitle: m.needCount > 0
                                              ? '${m.role} · ${m.needCount} 人评'
                                              : m.role,
                                          score: m.needScore,
                                          onTap: () => _openMember(m),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 18, 20, 0),
                                child: CommentList(
                                  comments: d.comments,
                                  onAgentPending: _onAgentPending,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DetailBar(
                          label: '支持打分',
                          onRate: _rate,
                          onShare: _share,
                        ),
                      ],
                    ),
    );
  }
}

/// 需求配图：单张宽图，多张两列网格，点击查看大图
class _NeedImages extends StatelessWidget {
  final List<String> images;

  const _NeedImages({required this.images});

  void _open(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerPage(images: images, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return GestureDetector(
        onTap: () => _open(context, 0),
        child: RemoteImage(
          url: images.first,
          width: double.infinity,
          height: 200,
          radius: BorderRadius.circular(12),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) => GestureDetector(
        onTap: () => _open(context, i),
        child: RemoteImage(
          url: images[i],
          radius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
