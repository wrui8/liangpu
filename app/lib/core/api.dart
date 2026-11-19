import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'agent_models.dart';
import 'models.dart';

class ApiException implements Exception {
  final String message;
  final int? status;

  ApiException(this.message, [this.status]);

  @override
  String toString() => message;
}

String normalizeServerUrl(String input) {
  var url = input.trim();
  if (url.isEmpty) return url;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  // 服务器已强制 HTTPS：老版本保存的明文地址自动升级（本机调试地址除外）。
  final uri = Uri.tryParse(url);
  if (uri != null && uri.scheme == 'http') {
    const local = {'localhost', '127.0.0.1', '::1'};
    if (!local.contains(uri.host)) {
      url = 'https://${url.substring('http://'.length)}';
    }
  }
  while (url.endsWith('/')) {
    url = url.substring(0, url.length - 1);
  }
  return url;
}

class Api {
  String baseUrl;
  String? token;
  final void Function()? onUnauthorized;
  final http.Client _client;
  final Map<String, Uint8List> _imageCache = {};

  Api({
    required this.baseUrl,
    this.token,
    Uint8List? caBytes,
    this.onUnauthorized,
  }) : _client = _buildClient(caBytes);

  /// 使用内置 CA 时只信任该 CA（证书固定），不透支系统根证书。
  static http.Client _buildClient(Uint8List? caBytes) {
    if (caBytes == null) return http.Client();
    final context = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(caBytes);
    return IOClient(HttpClient(context: context));
  }

  Map<String, String> _headers() {
    final h = <String, String>{
      'Accept': 'application/json',
      // 客户端协议版本：服务端可据此裁剪 Agent 新协议，不需要重新发版
      'X-LP-Client': '1',
    };
    // 公开接口也带上 token：用于返回「我是否点过赞」等状态
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  /// 拼接服务器绝对地址（动态配图返回 /uploads/xxx.jpg）
  String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    bool auth = false,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (baseUrl.isEmpty) throw ApiException('请先设置服务器地址（向运维获取）');
    Uri uri;
    try {
      uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    } catch (_) {
      throw ApiException('服务器地址格式不正确');
    }
    final headers = _headers();
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }

    http.Response res;
    try {
      final encoded = body == null ? null : jsonEncode(body);
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: encoded),
        'PUT' => _client.put(uri, headers: headers, body: encoded),
        'PATCH' => _client.patch(uri, headers: headers, body: encoded),
        'DELETE' => _client.delete(uri, headers: headers, body: encoded),
        _ => throw ArgumentError(method),
      };
      res = await future.timeout(timeout);
    } on HandshakeException {
      throw ApiException('服务器证书校验失败，请使用最新客户端并确认服务器地址');
    } on TlsException {
      throw ApiException('服务器证书校验失败，请使用最新客户端并确认服务器地址');
    } on TimeoutException {
      throw ApiException('连接服务器超时，请检查内网地址');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('无法连接服务器，请检查服务器地址与内网连接');
    }

    dynamic data;
    final text = utf8.decode(res.bodyBytes);
    if (text.isNotEmpty) {
      try {
        data = jsonDecode(text);
      } catch (_) {
        data = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }
    if (res.statusCode == 401 && auth) onUnauthorized?.call();
    final msg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : '请求失败（${res.statusCode}）';
    throw ApiException(msg, res.statusCode);
  }

  Future<bool> health() async {
    final data = await _request('GET', '/api/health');
    return data is Map && data['ok'] == true;
  }

  Future<List<LpIcon>> icons() async {
    final data = await _request('GET', '/api/icons');
    final list = (data['icons'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(LpIcon.fromJson).toList();
  }

  Future<List<Team>> teams({String? category, String? keyword}) async {
    final data = await _request('GET', '/api/teams', query: {
      if (category != null && category.isNotEmpty) 'category': category,
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
    });
    final list = (data['teams'] as List?) ?? const [];
    return list.whereType<Map<String, dynamic>>().map(Team.fromJson).toList();
  }

  Future<TeamDetail> teamDetail(int id) async {
    final data = await _request('GET', '/api/teams/$id');
    final team = Team.fromJson(
      data['team'] as Map<String, dynamic>,
    );
    final employees = ((data['employees'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Employee.fromJson)
        .toList();
    final comments = ((data['comments'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
    return TeamDetail(team, employees, comments);
  }

  /// 全部员工（发布需求时选择相关员工）
  Future<List<Employee>> employees() async {
    final data = await _request('GET', '/api/employees');
    final list = (data['employees'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(Employee.fromJson)
        .toList();
  }

  Future<EmployeeDetail> employeeDetail(int id) async {
    final data = await _request('GET', '/api/employees/$id');
    final employee = Employee.fromJson(
      data['employee'] as Map<String, dynamic>,
    );
    final team = Team.fromJson(data['team'] as Map<String, dynamic>);
    final comments = ((data['comments'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
    final needScores = ((data['needScores'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NeedMemberScore.fromJson)
        .toList();
    return EmployeeDetail(employee, team, comments, needScores: needScores);
  }

  Future<List<Need>> needs({String? status}) async {
    final data = await _request('GET', '/api/needs', query: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
    final list = (data['needs'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((j) => Need.fromJson(j))
        .toList();
  }

  Future<NeedDetail> needDetail(int id) async {
    final data = await _request('GET', '/api/needs/$id');
    final need = Need.fromJson(
      data['need'] as Map<String, dynamic>,
      detail: true,
    );
    // 详情接口 members 与 need 平级
    final members = ((data['members'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NeedMember.fromDetail)
        .toList();
    final merged = Need(
      id: need.id,
      title: need.title,
      desc: need.desc,
      category: need.category,
      status: need.status,
      teamId: need.teamId,
      teamName: need.teamName,
      proposerName: need.proposerName,
      proposerId: need.proposerId,
      images: need.images,
      score: need.score,
      count: need.count,
      dist: need.dist,
      tags: need.tags,
      createdAt: need.createdAt,
      members: members,
    );
    final comments = ((data['comments'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
    return NeedDetail(merged, comments);
  }

  /// 发布需求：状态固定「评审中」，初始 0 分
  Future<Need> createNeed({
    required String title,
    required String desc,
    required String category,
    int? teamId,
    List<String> tags = const [],
    List<Map<String, dynamic>> members = const [],
    List<String> images = const [],
  }) async {
    final data = await _request(
      'POST',
      '/api/needs',
      auth: true,
      body: {
        'title': title,
        'desc': desc,
        'category': category,
        'teamId': ?teamId,
        if (tags.isNotEmpty) 'tags': tags,
        if (members.isNotEmpty) 'members': members,
        if (images.isNotEmpty) 'images': images,
      },
      timeout: const Duration(seconds: 60),
    );
    return Need.fromJson(data['need'] as Map<String, dynamic>);
  }

  /// 编辑需求：仅本人或管理员；状态与评分不能通过该接口修改
  Future<Need> updateNeed(
    int id, {
    required String title,
    required String desc,
    required String category,
    int? teamId,
    List<String> tags = const [],
    List<Map<String, dynamic>> members = const [],
    List<String> images = const [],
  }) async {
    final data = await _request(
      'PUT',
      '/api/needs/$id',
      auth: true,
      body: {
        'title': title,
        'desc': desc,
        'category': category,
        'teamId': teamId,
        'tags': tags,
        'members': members,
        // 编辑时额外传旧图的 /uploads/ 地址，服务端保留并清理被移除的图片
        'images': images,
      },
      timeout: const Duration(seconds: 60),
    );
    return Need.fromJson(data['need'] as Map<String, dynamic>);
  }

  Future<void> deleteNeed(int id) async {
    await _request('DELETE', '/api/needs/$id', auth: true);
  }

  /// [scopeType]/[scopeId]：需求维度评分（scopeType='need' 时 scopeId 为需求 id），
  /// 只影响该需求内该成员的表现分，不写入员工全局分与团队分。
  Future<RatingAction> rate({
    required String targetType,
    required int targetId,
    required int score,
    String? content,
    List<Map<String, dynamic>>? mentions,
    String? scopeType,
    int? scopeId,
  }) async {
    final data = await _request(
      'POST',
      '/api/ratings',
      auth: true,
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'score': score,
        if (content != null && content.trim().isNotEmpty)
          'content': content.trim(),
        if (mentions != null && mentions.isNotEmpty) 'mentions': mentions,
        'scopeType': ?scopeType,
        'scopeId': ?scopeId,
      },
    );
    return RatingAction.fromJson(data as Map<String, dynamic>);
  }

  Future<({bool liked, int likes})> likeComment(int id) async {
    final data = await _request(
      'POST',
      '/api/comments/$id/like',
      auth: true,
      body: const {},
    );
    return (
      liked: data['liked'] == true,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Uint8List> imageBytes(String path) async {
    final url = resolveUrl(path);
    final cached = _imageCache[url];
    if (cached != null) return cached;
    http.Response res;
    try {
      res = await _client
          .get(Uri.parse(url), headers: {'Accept': 'image/*'})
          .timeout(const Duration(seconds: 20));
    } on HandshakeException {
      throw ApiException('图片证书校验失败');
    } on TimeoutException {
      throw ApiException('图片加载超时');
    } catch (_) {
      throw ApiException('图片加载失败');
    }
    if (res.statusCode != 200) {
      throw ApiException('图片加载失败（${res.statusCode}）');
    }
    if (_imageCache.length > 60) _imageCache.clear();
    _imageCache[url] = res.bodyBytes;
    return res.bodyBytes;
  }

  Post _parsePost(Map<String, dynamic> j) {
    final rawImages = (j['images'] as List?) ?? const [];
    return Post.fromJson(
      j,
      images: rawImages.map((e) => resolveUrl('$e')).toList(),
    );
  }

  Future<List<Post>> posts({int? userId}) async {
    final data = await _request('GET', '/api/posts', query: {
      if (userId != null) 'userId': '$userId',
    });
    final list = (data['posts'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(_parsePost)
        .toList();
  }

  Future<Post> createPost({
    required String content,
    List<String> images = const [],
  }) async {
    final data = await _request(
      'POST',
      '/api/posts',
      auth: true,
      body: {
        'content': content,
        if (images.isNotEmpty) 'images': images,
      },
      timeout: const Duration(seconds: 60),
    );
    return _parsePost(data['post'] as Map<String, dynamic>);
  }

  Future<({bool liked, int likes})> likePost(int id) async {
    final data = await _request(
      'POST',
      '/api/posts/$id/like',
      auth: true,
      body: const {},
    );
    return (
      liked: data['liked'] == true,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
    );
  }

  Future<PostDetail> postDetail(int id) async {
    final data = await _request('GET', '/api/posts/$id');
    final post = _parsePost(data['post'] as Map<String, dynamic>);
    final comments = ((data['comments'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
    return PostDetail(post, comments);
  }

  Future<Comment> commentPost(
    int id,
    String content, {
    List<Map<String, dynamic>>? mentions,
  }) async {
    final data = await _request(
      'POST',
      '/api/posts/$id/comment',
      auth: true,
      body: {
        'content': content,
        if (mentions != null && mentions.isNotEmpty) 'mentions': mentions,
      },
    );
    final c = Comment.fromJson(data['comment'] as Map<String, dynamic>);
    return data['agentPending'] == true ? c.copyWith(agentPending: true) : c;
  }

  Future<void> deletePost(int id) async {
    await _request('DELETE', '/api/posts/$id', auth: true);
  }

  /// 通知列表 + 未读数（进入通知页时使用）
  Future<({List<NotificationItem> list, int unread})> notifications() async {
    final data = await _request('GET', '/api/notifications', auth: true);
    final list = ((data['notifications'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationItem.fromJson)
        .toList();
    return (list: list, unread: (data['unread'] as num?)?.toInt() ?? 0);
  }

  /// 只取未读数：铃铛红点轮询
  Future<int> unreadNotifications() async {
    final data = await _request('GET', '/api/notifications/unread', auth: true);
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// 标记已读：带 id 只标记一条，不带则全部标记
  Future<void> markNotificationsRead({int? id}) async {
    await _request(
      'POST',
      '/api/notifications/read',
      auth: true,
      body: {'id': ?id},
    );
  }

  Future<UserProfile> userProfile(int id) async {
    final data = await _request('GET', '/api/users/$id');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<Comment> replyComment(
    int id,
    String content, {
    List<Map<String, dynamic>>? mentions,
  }) async {
    final data = await _request(
      'POST',
      '/api/comments/$id/reply',
      auth: true,
      body: {
        'content': content,
        if (mentions != null && mentions.isNotEmpty) 'mentions': mentions,
      },
    );
    final c = Comment.fromJson(data['comment'] as Map<String, dynamic>);
    return data['agentPending'] == true ? c.copyWith(agentPending: true) : c;
  }

  Future<({String token, LpUser user})> login(
    String username,
    String password,
  ) async {
    final data = await _request(
      'POST',
      '/api/auth/login',
      body: {'username': username, 'password': password},
    );
    return (
      token: '${data['token']}',
      user: LpUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, LpUser user})> register({
    required String username,
    required String password,
    required String nickname,
  }) async {
    final data = await _request(
      'POST',
      '/api/auth/register',
      body: {
        'username': username,
        'password': password,
        'nickname': nickname,
      },
    );
    return (
      token: '${data['token']}',
      user: LpUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<LpUser?> me() async {
    final data = await _request('GET', '/api/me', auth: true);
    final u = data is Map ? data['user'] : null;
    return u is Map<String, dynamic> ? LpUser.fromJson(u) : null;
  }

  Future<LpUser> patchMe({String? nickname, String? avatarIcon}) async {
    final data = await _request(
      'PATCH',
      '/api/me',
      auth: true,
      body: {
        'nickname': ?nickname,
        'avatarIcon': ?avatarIcon,
      },
    );
    return LpUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<MyRating>> myRatings() async {
    final data = await _request('GET', '/api/me/ratings', auth: true);
    final list = (data['ratings'] as List?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MyRating.fromJson)
        .toList();
  }

  /// Agent 名称 / 形象 / 别名 / 问候语 / 快捷指令（管理端改完即可同步）
  Future<AgentMeta> agentMeta() async {
    final data = await _request('GET', '/api/agent/meta');
    return AgentMeta.fromJson(data as Map<String, dynamic>);
  }

  /// 新建对话，返回会话 id
  Future<int> createAgentConversation(int agentId) async {
    final data = await _request(
      'POST',
      '/api/agent/conversations',
      auth: true,
      body: {'agentId': agentId},
    );
    final conv = data is Map ? data['conversation'] : null;
    final id = conv is Map ? (conv['id'] as num?)?.toInt() : null;
    final fallback = data is Map ? (data['conversationId'] as num?)?.toInt() : null;
    final out = id ?? fallback;
    if (out == null) throw ApiException('会话创建失败');
    return out;
  }

  /// 流式聊天：解析 SSE 的 event/data，逐条产出 AgentEvent
  Stream<AgentEvent> streamAgentMessage({
    required int conversationId,
    required String content,
    Map<String, dynamic>? context,
  }) async* {
    if (baseUrl.isEmpty) throw ApiException('请先设置服务器地址（向运维获取）');
    final uri = Uri.parse('$baseUrl/api/agent/conversations/$conversationId/messages');
    final req = http.Request('POST', uri);
    req.headers.addAll(_headers());
    req.headers['Content-Type'] = 'application/json; charset=utf-8';
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Cache-Control'] = 'no-cache';
    req.body = jsonEncode({
      'content': content,
      'context': ?context,
    });

    http.StreamedResponse res;
    try {
      res = await _client.send(req).timeout(const Duration(seconds: 30));
    } on HandshakeException {
      throw ApiException('服务器证书校验失败，请使用最新客户端并确认服务器地址');
    } on TlsException {
      throw ApiException('服务器证书校验失败，请使用最新客户端并确认服务器地址');
    } on TimeoutException {
      throw ApiException('Agent 连接超时，请稍后再试');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('无法连接 Agent 服务');
    }

    if (res.statusCode == 401) {
      onUnauthorized?.call();
      throw ApiException('登录已过期，请重新登录', 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      var msg = '请求失败（${res.statusCode}）';
      try {
        final text = await utf8.decoder.bind(res.stream).join();
        final data = jsonDecode(text);
        if (data is Map && data['error'] is String) msg = data['error'] as String;
      } catch (_) {
        /* 保持默认错误文案 */
      }
      throw ApiException(msg, res.statusCode);
    }

    var event = 'message';
    final data = StringBuffer();
    try {
      final lines = res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.isEmpty) {
          if (data.isNotEmpty) {
            yield AgentEvent.parse(event, data.toString());
            event = 'message';
            data.clear();
          }
          continue;
        }
        if (line.startsWith(':')) continue; // 心跳注释
        if (line.startsWith('event:')) {
          event = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          var v = line.substring(5);
          if (v.startsWith(' ')) v = v.substring(1);
          if (data.isNotEmpty) data.write('\n');
          data.write(v);
        }
      }
      if (data.isNotEmpty) yield AgentEvent.parse(event, data.toString());
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Agent 连接中断，请稍后再试');
    }
  }
}
