import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';
import '../widgets/post_card.dart';

/// 用户主页：展示公开资料与其发布的全部动态（支持跨用户查看）
class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({super.key, required this.userId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  UserProfile? _profile;
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
    final api = AppScope.of(context).api;
    try {
      final results = await Future.wait([
        api.userProfile(widget.userId),
        api.posts(userId: widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserProfile;
        _posts = results[1] as List<Post>;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_profile == null) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _joinedAt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}/${d.month}/${d.day} 加入';
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);
    final p = _profile;
    final posts = _posts;

    Widget body;
    if (_loading && p == null) {
      body = const LoadingView();
    } else if (_error != null && p == null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else if (p == null) {
      body = const SizedBox.shrink();
    } else {
      body = RefreshIndicator(
        onRefresh: () => _load(silent: true),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: kShadowLight,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        svg: app.iconSvg(p.avatarIcon),
                        fallbackName: p.nickname,
                        size: 62,
                        borderWidth: 2,
                        borderColor: c.brandSoft,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    p.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: c.text1,
                                    ),
                                  ),
                                ),
                                if (p.isSelf) ...[
                                  const SizedBox(width: 7),
                                  TagChip('我', red: true),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              [
                                p.role == 'admin' ? '管理员' : '正式员工',
                                _joinedAt(p.createdAt),
                              ].where((s) => s.isNotEmpty).join(' · '),
                              style: TextStyle(fontSize: 11, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _stat(c, '${p.posts}', '动态'),
                        Container(width: 1, height: 24, color: c.line),
                        _stat(c, '${p.likes}', '获赞'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: SectionTitle(p.isSelf ? '我的动态' : '${p.nickname}的动态'),
            ),
            if (posts == null)
              const LoadingView()
            else if (posts.isEmpty)
              EmptyView(
                icon: '📝',
                title: p.isSelf ? '你还没有发布动态' : 'TA 还没有发布动态',
                desc: p.isSelf ? '去「动态」页点右上角发布吧。' : '',
              )
            else
              for (final post in posts)
                PostCard(
                  key: ValueKey(post.id),
                  post: post,
                  showUser: false,
                  /* 当前已在该用户主页，不再提供「查看主页」入口，避免无限进入同一页 */
                  showProfileLink: false,
                  onDeleted: () {
                    setState(() {
                      _posts = [...posts]..removeWhere((x) => x.id == post.id);
                    });
                  },
                ),
            const FootNote('仅展示公开资料与用户主动发布的内容'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: p?.nickname ?? '用户主页',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: body,
    );
  }

  Widget _stat(LpColors c, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: c.text1,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10.5, color: c.text3)),
        ],
      ),
    );
  }
}
