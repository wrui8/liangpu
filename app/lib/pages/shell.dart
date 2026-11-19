import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/cover.dart';
import 'home_page.dart';
import 'moments_page.dart';
import 'me_page.dart';
import 'needs_page.dart';
import 'server_setup_page.dart';
import 'teams_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /* 切回前台立刻补拉未读数与 Agent 配置，不必等轮询 */
    if (state == AppLifecycleState.resumed) {
      final app = AppScope.of(context);
      app.refreshUnreadNotifications();
      app.loadAgentMeta(force: true);
    }
  }

  static final _tabs = <({String icon, String label})>[
    (icon: Ui.home, label: '首页'),
    (icon: Ui.teams, label: '团队'),
    (icon: Ui.needs, label: '需求'),
    (icon: Ui.community, label: '动态'),
    (icon: Ui.me, label: '我的'),
  ];

  void _switch(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    final app = AppScope.of(context);
    if (i == 0 || i == 1) app.loadTeams(force: true);
    if (i == 2) app.loadNeeds(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    /* 未设置服务器地址时先引导填写，避免所有页面都报连接失败 */
    if (app.serverUrl.isEmpty) return const ServerSetupPage();
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: const [
                    HomePage(),
                    TeamsPage(),
                    NeedsPage(),
                    MomentsPage(),
                    MePage(),
                  ],
                ),
              ),
              _TabBar(tabs: _tabs, index: _index, onTap: _switch),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final List<({String icon, String label})> tabs;
  final int index;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.tabs,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgIcon(
                          tabs[i].icon,
                          size: 22,
                          color: index == i ? c.brand : c.text3,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          tabs[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: index == i ? c.brand : c.text3,
                          ),
                        ),
                      ],
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
