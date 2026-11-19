import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import 'employee_detail_page.dart';
import 'need_detail_page.dart';
import 'team_detail_page.dart';

class MyRatingsPage extends StatefulWidget {
  const MyRatingsPage({super.key});

  @override
  State<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends State<MyRatingsPage> {
  List<MyRating>? _ratings;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      setState(() {
        _loading = false;
        _error = '请先登录';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await app.api.myRatings();
      if (!mounted) return;
      setState(() => _ratings = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(MyRating r) {
    Widget page;
    switch (r.targetType) {
      case 'team':
        page = TeamDetailPage(teamId: r.targetId);
        break;
      case 'employee':
        page = EmployeeDetailPage(employeeId: r.targetId);
        break;
      default:
        page = NeedDetailPage(needId: r.targetId);
    }
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => page))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final list = _ratings ?? const <MyRating>[];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '我的评分',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: c.brand,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (_loading && list.isEmpty)
              const LoadingView()
            else if (_error != null && list.isEmpty)
              ErrorView(message: _error!, onRetry: _load)
            else if (list.isEmpty)
              const EmptyView(
                icon: '⭐',
                title: '还没有评分',
                desc: '去首页给团队、同事或需求打个分吧',
              )
            else
              for (final r in list) _row(context, r, c),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, MyRating r, LpColors c) {
    final short = r.name.isEmpty ? '?' : r.name.characters.first;
    return GestureDetector(
      onTap: () => _open(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: kShadowLight,
        ),
        child: Row(
          children: [
            TeamCover(
              iconKey: r.iconKey,
              color1: r.color1,
              color2: r.color2,
              short: r.targetType == 'need' ? '需' : short,
              width: 40,
              height: 40,
              radius: 10,
              animate: false,
              iconRatio: r.targetType == 'need' ? 0.55 : 0.5,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (r.sub.isNotEmpty) r.sub,
                      timeAgo(r.updatedAt),
                    ].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${r.score}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: c.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
