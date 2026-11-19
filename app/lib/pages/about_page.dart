import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = LpColors.of(context);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '关于良扑',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: c.brand.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                '良',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '良扑',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: c.text1,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'v0.1.0 · 内网版',
              style: TextStyle(fontSize: 12, color: c.text3),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: kShadowLight,
            ),
            child: Column(
              children: [
                MenuRow(
                  label: '服务器地址',
                  trailing: Text(
                    app.serverUrl.isEmpty
                        ? '请向运维获取'
                        : app.serverUrl.replaceFirst(
                            RegExp(r'^https?://'),
                            '',
                          ),
                    style: TextStyle(fontSize: 12, color: c.text3),
                  ),
                ),
                const MenuRow(label: '评分体系', trailing: Text('1-10 分 · 一人一票')),
                const MenuRow(
                  label: '口号',
                  trailing: Text('给你身边的团队和同事打分'),
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            '良扑是一款内网团队评分应用。你可以为团队、员工和需求打分，'
            '短评会被收录为亮评，得分高者优先获得资源与支持。\n\n'
            '数据由内网服务器统一维护，管理端可对团队、员工、需求与图标进行管理。',
            style: TextStyle(fontSize: 13, height: 1.8, color: c.text2),
          ),
          const FootNote('良扑 · 内网访问 · 请勿外传'),
        ],
      ),
    );
  }
}
