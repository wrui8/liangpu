import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/cards.dart';
import '../widgets/common.dart';
import 'login_page.dart';
import 'need_composer_page.dart';
import 'need_detail_page.dart';

class NeedsPage extends StatefulWidget {
  const NeedsPage({super.key});

  @override
  State<NeedsPage> createState() => _NeedsPageState();
}

class _NeedsPageState extends State<NeedsPage> {
  String _filter = '全部';
  bool _requested = false;

  /// 排序策略：hot=按支持度，new=按最新发布
  String _sort = 'hot';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;
    _requested = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadNeeds();
    });
  }

  /// 发布需求：未登录先登录，发布成功后刷新列表
  Future<void> _compose() async {
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true || !mounted) return;
    }
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NeedComposerPage()),
    );
    if (posted == true && mounted) {
      AppScope.of(context).loadNeeds(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final all = app.needs;
    final list = (_filter == '全部'
        ? [...all]
        : all.where((n) => n.status == _filter).toList());
    if (_sort == 'hot') {
      list.sort((a, b) => b.score.compareTo(a.score));
    } else {
      list.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    }
    final showError = app.needsError != null && all.isEmpty;
    final showLoading = app.needsLoading && all.isEmpty;

    return Column(
      children: [
        LpAppBar(
          title: '需求广场',
          actions: [
            const ThemeButton(),
            IconBtn(Ui.plus, onTap: _compose),
          ],
        ),
        ChipBar(
          options: const ['全部', '评审中', '进行中', '已完成'],
          value: _filter,
          onChanged: (v) => setState(() => _filter = v),
        ),
        SectionHead(
          title: '大家的想法',
          more: _sort == 'hot' ? '按支持度排序' : '按最新发布排序',
          onTapMore: () =>
              setState(() => _sort = _sort == 'hot' ? 'new' : 'hot'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        ),
        Expanded(
          child: RefreshIndicator(
            color: c.brand,
            onRefresh: () => app.loadNeeds(force: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                if (showLoading)
                  const LoadingView()
                else if (showError)
                  ErrorView(
                    message: app.needsError ?? '加载失败',
                    onRetry: () => app.loadNeeds(force: true),
                  )
                else if (list.isEmpty)
                  const EmptyView(
                    icon: '💡',
                    title: '暂无相关需求',
                    desc: '换个状态看看吧',
                  )
                else
                  for (final n in list)
                    NeedCard(
                      need: n,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NeedDetailPage(needId: n.id),
                        ),
                      ),
                    ),
                const FootNote('支持度由全员打分决定 · 得分越高的需求越优先'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
