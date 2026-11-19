import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import 'about_page.dart';
import 'avatar_pool_page.dart';
import 'login_page.dart';
import 'my_ratings_page.dart';
import 'user_profile_page.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  List<MyRating>? _ratings;
  int? _loadedUserId;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      _loadedUserId = null;
      if (_ratings != null) _ratings = null;
      return;
    }
    final uid = app.user!.id;
    if (_loadedUserId != uid && !_loading) {
      _loadedUserId = uid;
      _loadRatings();
    }
  }

  Future<void> _loadRatings() async {
    if (!mounted) return;
    final app = AppScope.of(context);
    setState(() => _loading = true);
    try {
      final list = await app.api.myRatings();
      if (!mounted) return;
      setState(() => _ratings = list);
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _ratings = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _login() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true && mounted) _loadRatings();
  }

  Future<void> _logout() async {
    final c = LpColors.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后仍可浏览评分，但需要重新登录才能打分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('退出', style: TextStyle(color: c.brand)),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await AppScope.of(context).logout();
      if (mounted) setState(() => _ratings = null);
    }
  }

  void _openMyRatings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MyRatingsPage()))
        .then((_) => _loadRatings());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final user = app.user;
    final avatarSvg = app.iconSvg(user?.avatarIcon);
    final preview = (_ratings ?? const <MyRating>[]).take(3).toList();

    return Column(
      children: [
        const LpAppBar(title: '我的', actions: [ThemeButton()]),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _profileCard(context, c, user, avatarSvg),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: kShadowLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    MenuRow(
                      label: '深色模式',
                      trailing: LpSwitch(
                        value: app.dark,
                        onChanged: (_) => app.toggleTheme(),
                      ),
                    ),
                    MenuRow(
                      label: '服务器地址',
                      onTap: () => showServerDialog(context),
                      trailing: Text(
                        app.serverUrl.isEmpty
                            ? '请向运维获取'
                            : app.serverUrl.replaceFirst(
                                RegExp(r'^https?://'),
                                '',
                              ),
                        style: TextStyle(fontSize: 12, color: c.text3),
                      ),
                      last: user == null,
                    ),
                    if (user != null) ...[
                      MenuRow(
                        label: '我的评分',
                        onTap: _openMyRatings,
                      ),
                      MenuRow(
                        label: '我的动态',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserProfilePage(userId: user.id),
                          ),
                        ),
                      ),
                      MenuRow(
                        label: '更换头像',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AvatarPoolPage(),
                          ),
                        ),
                      ),
                      MenuRow(
                        label: '关于良扑',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        ),
                      ),
                      MenuRow(
                        label: '退出登录',
                        onTap: _logout,
                        trailing: SvgIcon(
                          Ui.logout,
                          size: 16,
                          color: c.text3,
                        ),
                        last: true,
                      ),
                    ] else
                      MenuRow(
                        label: '关于良扑',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        ),
                        last: true,
                      ),
                  ],
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        '我的评分',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.text2,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _openMyRatings,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          '全部 ›',
                          style: TextStyle(fontSize: 11, color: c.text3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (preview.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                    child: Text(
                      _loading ? '加载中…' : '还没有评分，去首页打个分吧',
                      style: TextStyle(fontSize: 12, color: c.text3),
                    ),
                  )
                else
                  for (final r in preview)
                    _ratingRow(context, c, r),
              ],
              const SizedBox(height: 20),
              const FootNote('良扑 · 内网访问'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileCard(
    BuildContext context,
    LpColors c,
    LpUser? user,
    String? avatarSvg,
  ) {
    return GestureDetector(
      onTap: user == null
          ? _login
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: user.id),
                ),
              ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brand, const Color(0xFFB5121E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: c.brand.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
            Row(
              children: [
                UserAvatar(
                  svg: avatarSvg,
                  fallbackName: user?.nickname ?? '良',
                  size: 54,
                  borderWidth: 2,
                  borderColor: Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nickname ?? '还没登录',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user == null
                            ? '登录后为团队和同事打分'
                            : '已评 ${_ratings?.length ?? 0} 项 · @${user.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    user == null
                        ? '点此登录'
                        : (user.role == 'admin' ? '管理员' : '正式员工'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingRow(BuildContext context, LpColors c, MyRating r) {
    final short = r.name.isEmpty ? '?' : r.name.characters.first;
    return GestureDetector(
      onTap: _openMyRatings,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                    style: TextStyle(fontSize: 11, color: c.text3),
                  ),
                ],
              ),
            ),
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
