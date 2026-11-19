import 'package:material_ui/material_ui.dart';

import '../pages/employee_detail_page.dart';
import '../pages/need_detail_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/team_detail_page.dart';
import '../pages/user_profile_page.dart';
import 'navigator.dart';
import 'state.dart';

/// 面板 / 卡片里的 route 字符串由此统一跳转。
/// 新页面只要沿用 `type:id` 并在服务端下发即可，不需要改协议。
void openAgentRoute(BuildContext context, String? route) {
  if (route == null || route.isEmpty) return;
  final parts = route.split(':');
  if (parts.length != 2) return;
  final id = int.tryParse(parts[1]);
  if (id == null) return;

  final Widget? page = switch (parts[0]) {
    'team' => TeamDetailPage(teamId: id),
    'employee' => EmployeeDetailPage(employeeId: id),
    'need' => NeedDetailPage(needId: id),
    'post' => PostDetailPage(postId: id),
    'user' => UserProfilePage(userId: id),
    _ => null,
  };
  if (page == null) return;

  AppScope.of(context).agentUi.closePanel();
  rootNavigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => page),
  );
}
