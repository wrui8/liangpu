import 'dart:async';

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
import 'post_detail_page.dart';
import 'team_detail_page.dart';

/// 消息中心：获赞 / 回复 / 动态评论
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem>? _items;
  bool _loading = true;
  String? _error;
  final Set<int> _readIds = {};

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
    final app = AppScope.of(context);
    try {
      final r = await app.api.notifications();
      if (!mounted) return;
      setState(() {
        _items = r.list;
        _error = null;
      });
      /* 进入通知页即视为已读，铃铛红点同步清除；列表仍保留本次加载的未读高亮 */
      if (r.unread > 0) unawaited(app.markNotificationsRead());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_items == null) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(NotificationItem n) async {
    final app = AppScope.of(context);
    if (!n.read) {
      setState(() => _readIds.add(n.id));
      unawaited(app.markNotificationsRead(id: n.id));
    }
    final page = switch (n.targetType) {
      'team' => TeamDetailPage(teamId: n.targetId),
      'employee' => EmployeeDetailPage(employeeId: n.targetId),
      'need' => NeedDetailPage(needId: n.targetId),
      _ => PostDetailPage(postId: n.targetId),
    };
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) app.refreshUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final items = _items;

    Widget body;
    if (_loading && items == null) {
      body = const LoadingView();
    } else if (_error != null && items == null) {
      body = ErrorView(message: _error!, onRetry: _load);
    } else {
      final list = items ?? const <NotificationItem>[];
      body = RefreshIndicator(
        color: c.brand,
        onRefresh: () => _load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          children: [
            if (list.isEmpty)
              const EmptyView(
                icon: '🔔',
                title: '还没有消息',
                desc: '别人赞了你的评论、回复了你，或评论了你的动态时，会在这里提醒你。',
              )
            else
              for (final n in list)
                _NotificationTile(
                  key: ValueKey(n.id),
                  item: n,
                  unread: !n.read && !_readIds.contains(n.id),
                  onTap: () => _open(n),
                ),
            const FootNote('仅显示最近 50 条 · 下拉可刷新'),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '消息',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: body,
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem item;
  final bool unread;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.item,
    required this.unread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: BoxDecoration(
          color: unread ? c.brandSoft.withValues(alpha: 0.55) : c.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: kShadowLight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              svg: app.iconSvg(item.actor.avatarIcon),
              fallbackName: item.actor.nickname,
              size: 38,
              animate: false,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.actor.nickname,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: c.text1,
                          ),
                        ),
                        TextSpan(
                          text: ' ${item.actionText}',
                          style: TextStyle(
                            fontSize: 13,
                            color: c.text2,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.preview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: c.text2,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    timeAgo(item.createdAt),
                    style: TextStyle(fontSize: 10.5, color: c.text3),
                  ),
                ],
              ),
            ),
            if (unread) ...[
              const SizedBox(width: 8),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: c.brand,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
