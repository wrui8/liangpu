import 'package:material_ui/material_ui.dart';

import 'core/navigator.dart';
import 'core/state.dart';
import 'core/theme.dart';
import 'pages/shell.dart';
import 'widgets/agent/agent_overlay_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.init();
  state.loadIcons();
  runApp(LpApp(state: state));
}

class LpApp extends StatelessWidget {
  final AppState state;

  const LpApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => AppScope(
        state: state,
        child: MaterialApp(
          title: '良扑',
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          theme: buildLpTheme(false),
          darkTheme: buildLpTheme(true),
          themeMode: state.dark ? ThemeMode.dark : ThemeMode.light,
          home: const Shell(),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.2,
            child: AgentOverlayHost(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
