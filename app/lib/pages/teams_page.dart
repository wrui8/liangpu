import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import 'team_detail_page.dart';

class TeamsPage extends StatefulWidget {
  final bool standalone;

  const TeamsPage({super.key, this.standalone = false});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final _search = TextEditingController();
  String _keyword = '';
  int _sort = 0;
  bool _requested = false;

  static const _sorts = ['热度', '高分', '最新'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadTeams();
    });
  }

  List<Team> _visible(List<Team> all) {
    final kw = _keyword.trim().toLowerCase();
    final list = kw.isEmpty
        ? [...all]
        : all
            .where((t) =>
                t.name.toLowerCase().contains(kw) ||
                t.short.toLowerCase().contains(kw))
            .toList();
    switch (_sort) {
      case 1:
        list.sort((a, b) => b.score.compareTo(a.score));
        break;
      case 2:
        list.sort((a, b) => b.id.compareTo(a.id));
        break;
      default:
        list.sort((a, b) => b.count.compareTo(a.count));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final list = _visible(app.teams);
    final showError = app.teamsError != null && app.teams.isEmpty;
    final showLoading = app.teamsLoading && app.teams.isEmpty;

    return Column(
      children: [
        LpAppBar(
          title: '团队评分',
          leading: widget.standalone
              ? IconBtn(
                  Ui.back,
                  onTap: () => Navigator.of(context).maybePop(),
                )
              : null,
          actions: const [ThemeButton()],
        ),
        Container(
          height: 42,
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: kShadowLight,
          ),
          child: Row(
            children: [
              SvgIcon(Ui.search, size: 17, color: c.text3),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _keyword = v),
                  style: TextStyle(fontSize: 14, color: c.text1),
                  cursorColor: c.brand,
                  decoration: InputDecoration(
                    hintText: '搜索团队',
                    hintStyle: TextStyle(fontSize: 14, color: c.text3),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (_keyword.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _search.clear();
                    setState(() => _keyword = '');
                  },
                  child: SvgIcon(Ui.close, size: 15, color: c.text3),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              for (var i = 0; i < _sorts.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => setState(() => _sort = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sorts[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              _sort == i ? FontWeight.w700 : FontWeight.w500,
                          color: _sort == i ? c.text1 : c.text3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 16,
                        height: 3,
                        decoration: BoxDecoration(
                          color: _sort == i ? c.brand : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: c.brand,
            onRefresh: () => app.loadTeams(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                if (showLoading)
                  const LoadingView()
                else if (showError)
                  ErrorView(
                    message: app.teamsError ?? '加载失败',
                    onRetry: () => app.loadTeams(force: true),
                  )
                else if (list.isEmpty)
                  const EmptyView(
                    icon: '🔍',
                    title: '没有找到相关团队',
                    desc: '换个关键词试试',
                  )
                else
                  for (final t in list)
                    DeptRow(
                      team: t,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TeamDetailPage(teamId: t.id),
                          ),
                        );
                        // 团队分可能因员工评分变化，返回时刷新
                        if (context.mounted) {
                          AppScope.of(context).loadTeams(force: true);
                        }
                      },
                    ),
                FootNote('共 ${list.length} 个团队 · 数据实时更新'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
