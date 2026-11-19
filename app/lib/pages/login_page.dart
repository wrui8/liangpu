import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _nickname = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final app = AppScope.of(context);
    final username = _username.text.trim();
    final password = _password.text;
    final nickname = _nickname.text.trim();

    if (app.serverUrl.isEmpty) {
      setState(() => _error = '请先设置服务器地址（向运维获取）');
      await _editServer();
      return;
    }
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = '请填写用户名和密码');
      return;
    }
    if (_register && nickname.isEmpty) {
      setState(() => _error = '请填写昵称');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await app.register(username, password, nickname);
      } else {
        await app.login(username, password);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editServer() async {
    final changed = await showServerDialog(context);
    if (changed && mounted) {
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SvgIcon(
                                Ui.back,
                                size: 22,
                                color: c.text2,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: app.toggleTheme,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SvgIcon(
                                app.dark ? Ui.sun : Ui.moon,
                                size: 21,
                                color: c.text2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: c.brand,
                              borderRadius: BorderRadius.circular(14),
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
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '良扑',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: c.text1,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '给你身边的团队和同事打分',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.text3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: kShadowLight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _modeTab('登录', !_register, c, () {
                                  setState(() {
                                    _register = false;
                                    _error = null;
                                  });
                                }),
                                const SizedBox(width: 22),
                                _modeTab('注册', _register, c, () {
                                  setState(() {
                                    _register = true;
                                    _error = null;
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _field(
                              c,
                              controller: _username,
                              hint: '用户名',
                              icon: Ui.me,
                            ),
                            const SizedBox(height: 11),
                            _field(
                              c,
                              controller: _password,
                              hint: '密码',
                              icon: Ui.logout,
                              obscure: _obscure,
                              suffix: GestureDetector(
                                onTap: () =>
                                    setState(() => _obscure = !_obscure),
                                child: Text(
                                  _obscure ? '显示' : '隐藏',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: c.text3,
                                  ),
                                ),
                              ),
                            ),
                            if (_register) ...[
                              const SizedBox(height: 11),
                              _field(
                                c,
                                controller: _nickname,
                                hint: '昵称（最多 16 字）',
                                icon: Ui.info,
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 11),
                              Text(
                                _error!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: c.brand,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: _busy ? null : _submit,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _busy ? c.line : c.brand,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: _busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _register ? '注册并登录' : '登录',
                                        style: const TextStyle(
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
                      const SizedBox(height: 18),
                      Center(
                        child: GestureDetector(
                          onTap: _editServer,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgIcon(Ui.server, size: 13, color: c.text3),
                                const SizedBox(width: 5),
                                Text(
                                  app.serverUrl.isEmpty
                                      ? '服务器地址请向运维获取'
                                      : app.serverUrl,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: c.text3,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool on, LpColors c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                color: on ? c.text1 : c.text3,
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: on ? c.brand : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    LpColors c, {
    required TextEditingController controller,
    required String hint,
    required String icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          SvgIcon(icon, size: 17, color: c.text3),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              autocorrect: false,
              enableSuggestions: false,
              style: TextStyle(fontSize: 14, color: c.text1),
              cursorColor: c.brand,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14, color: c.text3),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          ?suffix,
        ],
      ),
    );
  }
}
