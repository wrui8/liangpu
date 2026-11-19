import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'agent_models.dart';
import 'agent_ui.dart';
import 'api.dart';
import 'models.dart';
import 'token_store.dart';

/// 不预置服务器地址：首次使用向运维获取后在登录页填写。
String defaultServerUrl() => '';

class AppState extends ChangeNotifier {
  static const _kToken = 'lp_token';
  static const _kUser = 'lp_user';
  static const _kServer = 'lp_server';
  static const _kDark = 'lp_dark';

  late SharedPreferences prefs;
  late Api api;
  late TokenStore _tokenStore;
  Uint8List? _caBytes;

  Map<String, LpIcon> icons = {};
  bool iconsLoaded = false;

  List<Team> teams = const [];
  List<Need> needs = const [];
  bool teamsLoaded = false;
  bool needsLoaded = false;
  bool teamsLoading = false;
  bool needsLoading = false;
  String? teamsError;
  String? needsError;

  LpUser? user;
  bool dark = false;
  String serverUrl = '';

  /// 未读通知数：首页铃铛红点
  int unreadNotifications = 0;
  Timer? _notifyTimer;

  /// Agent 配置由服务端 meta 下发，管理端修改后客户端定时/打开面板时同步
  AgentMeta? agentMeta;
  bool agentMetaLoaded = false;
  bool agentDemo = true;
  bool _agentMetaLoading = false;
  DateTime? _agentMetaAt;
  Timer? _agentMetaTimer;

  /// 悬浮球 / 迷你面板的全局状态
  final AgentUiController agentUi = AgentUiController();

  bool get loggedIn => user != null && api.token != null;

  /// 当前是否在使用前端内置演示（后端 Agent 接口尚未接入）
  /// 聊天与评论回复仍走本地演示脚本（服务端只下发 meta）
  bool get agentDemoActive => kAgentDemoChat;

  AgentProfile? get primaryAgent => agentMeta?.primary;

  /// 登录后每 30 秒拉一次未读数；切回前台时由 Shell 再补一次
  void _startNotifyPolling() {
    _notifyTimer?.cancel();
    if (serverUrl.isEmpty) return;
    unawaited(refreshUnreadNotifications());
    _notifyTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(refreshUnreadNotifications()),
    );

    /* Agent 配置：登录后立即拉取，之后每分钟同步一次管理端修改 */
    _agentMetaTimer?.cancel();
    unawaited(loadAgentMeta(force: true));
    _agentMetaTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(loadAgentMeta()),
    );
  }

  void _stopNotifyPolling() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    _agentMetaTimer?.cancel();
    _agentMetaTimer = null;
    if (unreadNotifications != 0) {
      unreadNotifications = 0;
      notifyListeners();
    }
  }

  /// 退出登录 / 换服务器时清掉 Agent 配置与面板状态
  void _clearAgent() {
    agentMeta = null;
    agentMetaLoaded = false;
    agentDemo = true;
    _agentMetaAt = null;
    agentUi.reset();
  }

  Future<void> refreshUnreadNotifications() async {
    if (!loggedIn) {
      if (unreadNotifications != 0) {
        unreadNotifications = 0;
        notifyListeners();
      }
      return;
    }
    try {
      final count = await api.unreadNotifications();
      if (count != unreadNotifications) {
        unreadNotifications = count;
        notifyListeners();
      }
    } catch (_) {
      /* 轮询失败静默，等下一次或用户刷新 */
    }
  }

  Future<void> markNotificationsRead({int? id}) async {
    if (!loggedIn) return;
    try {
      await api.markNotificationsRead(id: id);
    } catch (_) {
      return;
    }
    if (id == null) {
      if (unreadNotifications != 0) {
        unreadNotifications = 0;
        notifyListeners();
      }
    } else {
      await refreshUnreadNotifications();
    }
  }

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    final savedServer = prefs.getString(_kServer);
    serverUrl = normalizeServerUrl(
      (savedServer == null || savedServer.isEmpty)
          ? defaultServerUrl()
          : savedServer,
    );
    /* 未设置服务器地址时无法连接任何服务，旧的登录态一并失效，先引导用户填写地址 */
    dark = prefs.getBool(_kDark) ?? false;

    final ca = await rootBundle.load('assets/certs/ca.pem');
    _caBytes = ca.buffer.asUint8List(ca.offsetInBytes, ca.lengthInBytes);

    // token 存安全存储，只信任内置 CA；旧版的 SharedPreferences 明文 token 迁移一次。
    _tokenStore = createTokenStore(prefs);
    var token = await _tokenStore.read();
    final legacyToken = prefs.getString(_kToken);
    if ((token == null || token.isEmpty) && legacyToken != null && legacyToken.isNotEmpty) {
      token = legacyToken;
      await _tokenStore.write(legacyToken);
    }
    if (prefs.containsKey(_kToken)) await prefs.remove(_kToken);

    final rawUser = prefs.getString(_kUser);
    if (rawUser != null) {
      try {
        user = LpUser.fromJson(
          jsonDecode(rawUser) as Map<String, dynamic>,
        );
      } catch (_) {
        user = null;
      }
    }
    if (serverUrl.isEmpty) {
      token = null;
      user = null;
    }
    api = Api(
      baseUrl: serverUrl,
      token: token,
      caBytes: _caBytes,
      onUnauthorized: _onUnauthorized,
    );
    if (loggedIn) _startNotifyPolling();
    notifyListeners();
  }

  /// token 过期或被服务端拒绝时，清除本地登录态。
  void _onUnauthorized() {
    if (user == null && api.token == null) return;
    api.token = null;
    user = null;
    _stopNotifyPolling();
    _clearAgent();
    prefs.remove(_kUser);
    unawaited(_tokenStore.delete());
    notifyListeners();
  }

  /// 拉取 Agent meta；管理端修改名字 / 形象 / 介绍 / 问候语 / 快捷指令后，
  /// 客户端在下次轮询、打开面板或切回前台时自动同步，无需重新发版。
  Future<void> loadAgentMeta({bool force = false}) async {
    if (!loggedIn) {
      final changed = agentMeta != null;
      agentMeta = null;
      agentMetaLoaded = true;
      agentDemo = true;
      _agentMetaAt = null;
      if (changed) notifyListeners();
      return;
    }
    if (_agentMetaLoading) return;
    final now = DateTime.now();
    if (!force &&
        _agentMetaAt != null &&
        now.difference(_agentMetaAt!) < const Duration(seconds: 15)) {
      return;
    }
    _agentMetaLoading = true;
    try {
      final meta = await api.agentMeta();
      agentMeta = meta;
      agentDemo = false;
      _agentMetaAt = DateTime.now();
    } catch (_) {
      /* 后端 Agent 接口尚未上线时，预览期回退到内置小狮。
         已有服务端配置则不降级，避免网络抖动把管理端配置覆盖成演示数据。 */
      if (agentMeta == null && kAgentPreview) {
        agentMeta = AgentMeta.demo();
        agentDemo = true;
      }
    } finally {
      _agentMetaLoading = false;
      agentMetaLoaded = true;
      notifyListeners();
    }
  }

  /// 打开迷你面板：强制刷新一次 meta，确保管理端最新名字和文案已生效
  void openAgentPanel({String? prefill}) {
    unawaited(loadAgentMeta(force: true));
    agentUi.openPanel(prefillText: prefill);
  }

  bool textMentionsAgent(String text) => agentMeta?.matchesMention(text) ?? false;

  Future<void> loadIcons({bool force = false}) async {
    if (iconsLoaded && !force) return;
    if (api.baseUrl.isEmpty) return;
    try {
      final list = await api.icons();
      icons = {for (final i in list) i.key: i};
      iconsLoaded = true;
      notifyListeners();
    } catch (_) {
      // 静默失败：页面数据请求会给出连接错误
    }
  }

  String? iconSvg(String? key) {
    if (key == null || key.isEmpty) return null;
    return icons[key]?.svg;
  }

  List<LpIcon> iconsOfKind(String kind) {
    final list = icons.values.where((i) => i.kind == kind).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    return list;
  }

  Future<void> loadTeams({bool force = false}) async {
    if (teamsLoading) return;
    if (teamsLoaded && !force) return;
    teamsLoading = true;
    teamsError = null;
    notifyListeners();
    try {
      teams = await api.teams();
      teamsLoaded = true;
    } on ApiException catch (e) {
      teamsError = e.message;
    } finally {
      teamsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNeeds({bool force = false}) async {
    if (needsLoading) return;
    if (needsLoaded && !force) return;
    needsLoading = true;
    needsError = null;
    notifyListeners();
    try {
      needs = await api.needs();
      needsLoaded = true;
    } on ApiException catch (e) {
      needsError = e.message;
    } finally {
      needsLoading = false;
      notifyListeners();
    }
  }

  /// 评分后刷新列表聚合数据（静默）
  void refreshAggregates() {
    loadTeams(force: true);
    loadNeeds(force: true);
  }

  Future<void> login(String username, String password) async {
    final r = await api.login(username, password);
    await _applyAuth(r);
  }

  Future<void> register(String username, String password, String nickname) async {
    final r = await api.register(
      username: username,
      password: password,
      nickname: nickname,
    );
    await _applyAuth(r);
  }

  Future<void> _applyAuth(({String token, LpUser user}) r) async {
    api.token = r.token;
    user = r.user;
    await _tokenStore.write(r.token);
    await prefs.remove(_kToken);
    await prefs.setString(_kUser, jsonEncode(r.user.toJson()));
    _startNotifyPolling();
    notifyListeners();
  }

  Future<void> logout() async {
    user = null;
    api.token = null;
    _stopNotifyPolling();
    _clearAgent();
    await _tokenStore.delete();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (user == null) return;
    try {
      final u = await api.me();
      if (u != null) {
        user = u;
        await prefs.setString(_kUser, jsonEncode(u.toJson()));
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.status == 401) {
        await logout();
      }
    }
  }

  Future<void> setAvatar(String key) async {
    final u = await api.patchMe(avatarIcon: key);
    user = u;
    await prefs.setString(_kUser, jsonEncode(u.toJson()));
    notifyListeners();
  }

  Future<void> setNickname(String nickname) async {
    final u = await api.patchMe(nickname: nickname);
    user = u;
    await prefs.setString(_kUser, jsonEncode(u.toJson()));
    notifyListeners();
  }

  Future<void> setServer(String url) async {
    final n = normalizeServerUrl(url);
    if (n.isEmpty) throw ApiException('请填写服务器地址');
    if (n == api.baseUrl) return;
    serverUrl = n;
    api.baseUrl = n;
    api.token = null;
    user = null;
    _stopNotifyPolling();
    _clearAgent();
    icons = {};
    iconsLoaded = false;
    teams = const [];
    needs = const [];
    teamsLoaded = false;
    needsLoaded = false;
    teamsError = null;
    needsError = null;
    await prefs.setString(_kServer, n);
    await _tokenStore.delete();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }

  void toggleTheme() {
    dark = !dark;
    prefs.setBool(_kDark, dark);
    notifyListeners();
  }

  void setDark(bool value) {
    if (dark == value) return;
    dark = value;
    prefs.setBool(_kDark, dark);
    notifyListeners();
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    _agentMetaTimer?.cancel();
    agentUi.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope 未挂载');
    return scope!.notifier!;
  }
}
