import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../pages/login_page.dart';
import '../pages/notifications_page.dart';
import 'cover.dart';

/// 首页右上角铃铛：未读红点 + 进入消息中心
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  Future<void> _open(BuildContext context) async {
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true || !context.mounted) return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
    app.refreshUnreadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    final n = app.unreadNotifications;

    return GestureDetector(
      onTap: () => _open(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SvgIcon(Ui.bell, size: 21, color: c.text1),
            if (n > 0)
              Positioned(
                right: 5,
                top: 7,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 15),
                  height: 15,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.bg, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    n > 99 ? '99+' : '$n',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
