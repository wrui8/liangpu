import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import '../widgets/notification_bell.dart';
import 'team_detail_page.dart';
import 'teams_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filter = '全部';
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadTeams();
    });
  }

  Future<void> _openTeam(Team team) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TeamDetailPage(teamId: team.id)),
    );
    // 团队详情里给员工打分后，团队合并分可能变化，返回时刷新列表
    if (mounted) AppScope.of(context).loadTeams(force: true);
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamsPage(standalone: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final all = app.teams;
    final list = _filter == '全部'
        ? all
        : all.where((t) => t.category == _filter).toList();
    final hot = [...all]..sort((a, b) => b.count.compareTo(a.count));
    final hotList = hot.take(4).toList();
    final showError = app.teamsError != null && all.isEmpty;
    final showLoading = app.teamsLoading && all.isEmpty;

    return Column(
      children: [
        LpAppBar(
          logo: true,
          actions: [
            const NotificationBell(),
            const ThemeButton(),
            IconBtn(Ui.search, onTap: _openSearch),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            color: c.brand,
            onRefresh: () => app.loadTeams(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 4),
                ChipBar(
                  options: const ['全部', 'c', '中'],
                  value: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SectionHead(title: '今日热门', more: '实时热度 ›'),
                SizedBox(
                  height: 180,
                  child: hotList.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          itemCount: hotList.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => HotCard(
                            team: hotList[i],
                            onTap: () => _openTeam(hotList[i]),
                          ),
                        ),
                ),
                SectionHead(title: '团队评分', more: '共 ${list.length} 个团队'),
                if (showLoading)
                  const LoadingView()
                else if (showError)
                  ErrorView(
                    message: app.teamsError ?? '加载失败',
                    onRetry: () => app.loadTeams(force: true),
                  )
                else if (list.isEmpty)
                  const EmptyView(
                    icon: '🏷️',
                    title: '该分类下暂无团队',
                    desc: '换个分类看看吧',
                  )
                else
                  for (final t in list)
                    TeamScoreCard(team: t, onTap: () => _openTeam(t)),
                const FootNote('内网访问 · 良扑 v0.1'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
