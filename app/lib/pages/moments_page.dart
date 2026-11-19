import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import '../widgets/post_card.dart';
import 'composer_page.dart';
import 'login_page.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  List<Post>? _posts;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await AppScope.of(context).api.posts();
      if (!mounted) return;
      setState(() {
        _posts = list;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_posts == null) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _compose() async {
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ComposerPage()),
    );
    if (posted == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final posts = _posts;

    Widget body;
    if (_loading && posts == null) {
      body = const LoadingView();
    } else if (_error != null && posts == null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else {
      final list = posts ?? const <Post>[];
      body = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: c.brand,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '平台动态',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '按点赞量与发布时间排序',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.text3),
                    ),
                  ),
                ],
              ),
            ),
            if (list.isEmpty)
              EmptyView(
                icon: '📝',
                title: '还没有动态',
                desc: '点右上角「发布」，分享你的第一条动态。',
              )
            else
              for (final p in list)
                PostCard(
                  key: ValueKey(p.id),
                  post: p,
                  onDeleted: () {
                    setState(() {
                      _posts = [...list]..removeWhere((x) => x.id == p.id);
                    });
                  },
                ),
            FootNote('动态按热度排序 · 点击头像可查看该用户主页'),
          ],
        ),
      );
    }

    return Column(
      children: [
        LpAppBar(
          title: '动态',
          actions: [
            GestureDetector(
              onTap: _compose,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    SvgIcon(Ui.plus, size: 13, color: Colors.white),
                    const SizedBox(width: 3),
                    const Text(
                      '发布',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const ThemeButton(),
          ],
        ),
        Expanded(child: body),
      ],
    );
  }
}
