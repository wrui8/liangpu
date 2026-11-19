import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../widgets/common.dart';

/// 首次使用或未设置服务器地址时的引导页
class ServerSetupPage extends StatelessWidget {
  const ServerSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: c.brand,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: c.brand.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '良',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    '连接服务器',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: c.text1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '首次使用需要填写服务器地址。\n请向运维获取，填写一次后会记住。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.8, color: c.text2),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => showServerDialog(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 48,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: c.brand,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '设置服务器地址',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
