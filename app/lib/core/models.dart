num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;
int _int(dynamic v) => _num(v).toInt();
String _str(dynamic v) => v == null ? '' : '$v';
bool _bool(dynamic v) => v == true || v == 'true';

List<double> _dist(dynamic v) {
  final list = <double>[];
  if (v is List) {
    for (final e in v) {
      list.add(_num(e).toDouble());
    }
  }
  while (list.length < 10) {
    list.add(0);
  }
  return list.take(10).toList();
}

List<String> _tags(dynamic v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

class LpIcon {
  final int id;
  final String key;
  final String kind;
  final String name;
  final String svg;
  final int sort;

  LpIcon({
    required this.id,
    required this.key,
    required this.kind,
    required this.name,
    required this.svg,
    required this.sort,
  });

  factory LpIcon.fromJson(Map<String, dynamic> j) => LpIcon(
        id: _int(j['id']),
        key: _str(j['key']),
        kind: _str(j['kind']),
        name: _str(j['name']),
        svg: _str(j['svg']),
        sort: _int(j['sort']),
      );
}

class LpUser {
  final int id;
  final String username;
  final String nickname;
  final String role;
  final String avatarIcon;

  LpUser({
    required this.id,
    required this.username,
    required this.nickname,
    required this.role,
    required this.avatarIcon,
  });

  factory LpUser.fromJson(Map<String, dynamic> j) => LpUser(
        id: _int(j['id']),
        username: _str(j['username']),
        nickname: _str(j['nickname']),
        role: _str(j['role']),
        avatarIcon: _str(j['avatarIcon']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'role': role,
        'avatarIcon': avatarIcon,
      };
}

class Team {
  final int id;
  final String name;
  final String category;
  final String short;
  final String iconKey;
  final String color1;
  final String color2;
  final double score;
  final int count;
  final List<double> dist;
  final List<String> tags;
  final int employeeCount;
  final int sort;

  Team({
    required this.id,
    required this.name,
    required this.category,
    required this.short,
    required this.iconKey,
    required this.color1,
    required this.color2,
    required this.score,
    required this.count,
    required this.dist,
    required this.tags,
    required this.employeeCount,
    required this.sort,
  });

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: _int(j['id']),
        name: _str(j['name']),
        category: _str(j['category']),
        short: _str(j['short']),
        iconKey: _str(j['iconKey']),
        color1: _str(j['color1']),
        color2: _str(j['color2']),
        score: _num(j['score']).toDouble(),
        count: _int(j['count']),
        dist: _dist(j['dist']),
        tags: _tags(j['tags']),
        employeeCount: _int(j['employeeCount']),
        sort: _int(j['sort']),
      );
}

class Employee {
  final int id;
  final int teamId;
  final String name;
  final String title;
  final String? iconKey;
  final String short;
  final String color1;
  final String color2;
  final double score;
  final int count;
  final List<double> dist;
  final int sort;
  final String? teamName;

  Employee({
    required this.id,
    required this.teamId,
    required this.name,
    required this.title,
    required this.iconKey,
    required this.short,
    required this.color1,
    required this.color2,
    required this.score,
    required this.count,
    required this.dist,
    required this.sort,
    this.teamName,
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id: _int(j['id']),
        teamId: _int(j['teamId']),
        name: _str(j['name']),
        title: _str(j['title']),
        iconKey: (j['iconKey'] == null || '${j['iconKey']}'.isEmpty)
            ? null
            : _str(j['iconKey']),
        short: _str(j['short']),
        color1: _str(j['color1']),
        color2: _str(j['color2']),
        score: _num(j['score']).toDouble(),
        count: _int(j['count']),
        dist: _dist(j['dist']),
        sort: _int(j['sort']),
        teamName: j['teamName'] == null ? null : _str(j['teamName']),
      );
}

class NeedMember {
  final int employeeId;
  final String role;
  final String name;
  final String short;
  final String color1;
  final String color2;
  final String? iconKey;
  final double score;
  final int? teamId;
  final String? teamName;
  final String? title;

  /// 该成员在本需求中的平均表现分（与全局 score 隔离）
  final double needScore;
  final int needCount;
  final int? myScore;

  NeedMember({
    required this.employeeId,
    required this.role,
    required this.name,
    required this.short,
    required this.color1,
    required this.color2,
    required this.iconKey,
    required this.score,
    this.teamId,
    this.teamName,
    this.title,
    this.needScore = 0,
    this.needCount = 0,
    this.myScore,
  });

  /// 需求列表里的简版成员
  factory NeedMember.fromBrief(Map<String, dynamic> j) => NeedMember(
        employeeId: _int(j['employeeId']),
        role: _str(j['role']),
        name: _str(j['name']),
        short: _str(j['short']),
        color1: _str(j['color1']),
        color2: _str(j['color2']),
        iconKey: j['iconKey'] == null ? null : _str(j['iconKey']),
        score: 0,
      );

  /// 需求详情里的完整成员
  factory NeedMember.fromDetail(Map<String, dynamic> j) {
    final e = (j['employee'] as Map<String, dynamic>?) ?? const {};
    return NeedMember(
      employeeId: _int(e['id']),
      role: _str(j['role']),
      name: _str(e['name']),
      short: _str(e['short']),
      color1: _str(e['color1']),
      color2: _str(e['color2']),
      iconKey: e['iconKey'] == null ? null : _str(e['iconKey']),
      score: _num(e['score']).toDouble(),
      teamId: _int(e['teamId']),
      teamName: e['teamName'] == null ? null : _str(e['teamName']),
      title: e['title'] == null ? null : _str(e['title']),
      needScore: _num(j['needScore']).toDouble(),
      needCount: _int(j['needCount']),
      myScore: j['myScore'] == null ? null : _int(j['myScore']),
    );
  }
}

/// 员工在某个需求中的表现分
class NeedMemberScore {
  final int needId;
  final String title;
  final String status;
  final double score;
  final int count;
  final int? myScore;
  final DateTime? updatedAt;

  NeedMemberScore({
    required this.needId,
    required this.title,
    required this.status,
    required this.score,
    required this.count,
    this.myScore,
    this.updatedAt,
  });

  factory NeedMemberScore.fromJson(Map<String, dynamic> j) => NeedMemberScore(
        needId: _int(j['needId']),
        title: _str(j['title']),
        status: _str(j['status']),
        score: _num(j['score']).toDouble(),
        count: _int(j['count']),
        myScore: j['myScore'] == null ? null : _int(j['myScore']),
        updatedAt: j['updatedAt'] == null ? null : _date(j['updatedAt']),
      );
}

class Need {
  final int id;
  final String title;
  final String desc;
  final String category;
  final String status;
  final int? teamId;
  final String? teamName;
  final String? proposerName;

  /// 用户自行发布时的发布者 id；管理端录入为 null
  final int? proposerId;
  final List<String> images;
  final double score;
  final int count;
  final List<double> dist;
  final List<String> tags;
  final DateTime? createdAt;
  final List<NeedMember> members;

  Need({
    required this.id,
    required this.title,
    required this.desc,
    required this.category,
    required this.status,
    required this.teamId,
    required this.teamName,
    required this.proposerName,
    this.proposerId,
    this.images = const [],
    required this.score,
    required this.count,
    required this.dist,
    required this.tags,
    required this.createdAt,
    required this.members,
  });

  factory Need.fromJson(Map<String, dynamic> j, {bool detail = false}) => Need(
        id: _int(j['id']),
        title: _str(j['title']),
        desc: _str(j['desc']),
        category: _str(j['category']),
        status: _str(j['status']),
        teamId: j['teamId'] == null ? null : _int(j['teamId']),
        teamName: j['teamName'] == null ? null : _str(j['teamName']),
        proposerName: j['proposerName'] == null ? null : _str(j['proposerName']),
        proposerId: j['proposerId'] == null ? null : _int(j['proposerId']),
        images: _tags(j['images']),
        score: _num(j['score']).toDouble(),
        count: _int(j['count']),
        dist: _dist(j['dist']),
        tags: _tags(j['tags']),
        createdAt: _date(j['createdAt']),
        members: (j['members'] is List)
            ? (j['members'] as List)
                .whereType<Map<String, dynamic>>()
                .map((m) => detail ? NeedMember.fromDetail(m) : NeedMember.fromBrief(m))
                .toList()
            : const [],
      );
}

class Comment {
  final int id;
  final int userId;
  final String user;
  final String avatarIcon;
  final int score;
  final String text;
  final int likes;
  final bool liked;
  final int? parentId;
  final int? rootId;
  final int? replyToUserId;
  final String? replyToName;
  final int replyCount;
  final List<Comment> replies;
  final DateTime? createdAt;

  /// 是否为 Agent 的评论（后端下发，旧客户端会忽略）
  final bool isAgent;

  /// 后端已异步安排 Agent 回复，客户端可稍后刷新评论区
  final bool agentPending;

  Comment({
    required this.id,
    required this.userId,
    required this.user,
    required this.avatarIcon,
    required this.score,
    required this.text,
    required this.likes,
    required this.liked,
    required this.parentId,
    this.rootId,
    this.replyToUserId,
    this.replyToName,
    required this.replyCount,
    required this.replies,
    required this.createdAt,
    this.isAgent = false,
    this.agentPending = false,
  });

  factory Comment.fromJson(Map<String, dynamic> j) {
    final toName = j['replyToName'];
    return Comment(
      id: _int(j['id']),
      userId: _int(j['userId']),
      user: _str(j['user']),
      avatarIcon: _str(j['avatarIcon']),
      score: _int(j['score']),
      text: _str(j['text']),
      likes: _int(j['likes']),
      liked: _bool(j['liked']),
      parentId: j['parentId'] == null ? null : _int(j['parentId']),
      rootId: j['rootId'] == null ? null : _int(j['rootId']),
      replyToUserId:
          j['replyToUserId'] == null ? null : _int(j['replyToUserId']),
      replyToName: toName == null || '$toName'.isEmpty ? null : '$toName',
      replyCount: _int(j['replyCount']),
      replies: ((j['replies'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Comment.fromJson)
          .toList(),
      createdAt: _date(j['createdAt']),
      isAgent: _bool(j['isAgent']),
      agentPending: _bool(j['agentPending']),
    );
  }

  Comment copyWith({
    int? likes,
    bool? liked,
    int? replyCount,
    List<Comment>? replies,
    bool? isAgent,
    bool? agentPending,
  }) =>
      Comment(
        id: id,
        userId: userId,
        user: user,
        avatarIcon: avatarIcon,
        score: score,
        text: text,
        likes: likes ?? this.likes,
        liked: liked ?? this.liked,
        parentId: parentId,
        rootId: rootId,
        replyToUserId: replyToUserId,
        replyToName: replyToName,
        replyCount: replyCount ?? this.replyCount,
        replies: replies ?? this.replies,
        createdAt: createdAt,
        isAgent: isAgent ?? this.isAgent,
        agentPending: agentPending ?? this.agentPending,
      );
}

/// 动态作者（公开资料）
class PostAuthor {
  final int id;
  final String nickname;
  final String avatarIcon;
  final String role;

  PostAuthor({
    required this.id,
    required this.nickname,
    required this.avatarIcon,
    required this.role,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> j) => PostAuthor(
        id: _int(j['id']),
        nickname: _str(j['nickname']),
        avatarIcon: _str(j['avatarIcon']),
        role: _str(j['role']),
      );
}

class Post {
  final int id;
  final String content;
  final List<String> images;
  final int likes;
  final bool liked;
  final int commentCount;
  final DateTime? createdAt;
  final PostAuthor? user;

  Post({
    required this.id,
    required this.content,
    required this.images,
    required this.likes,
    required this.liked,
    this.commentCount = 0,
    required this.createdAt,
    required this.user,
  });

  factory Post.fromJson(Map<String, dynamic> j, {List<String>? images}) => Post(
        id: _int(j['id']),
        content: _str(j['content']),
        images: images ?? _tags(j['images']),
        likes: _int(j['likes']),
        liked: _bool(j['liked']),
        commentCount: _int(j['commentCount']),
        createdAt: _date(j['createdAt']),
        user: j['user'] is Map<String, dynamic>
            ? PostAuthor.fromJson(j['user'] as Map<String, dynamic>)
            : null,
      );

  Post copyWith({int? likes, bool? liked, int? commentCount}) => Post(
        id: id,
        content: content,
        images: images,
        likes: likes ?? this.likes,
        liked: liked ?? this.liked,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        user: user,
      );
}

/// 动态详情：动态内容 + 评论区
class PostDetail {
  final Post post;
  final List<Comment> comments;

  PostDetail(this.post, this.comments);
}

/// 通知（获赞 / 回复 / 动态评论）
class NotificationItem {
  final int id;
  final String type;
  final String targetType;
  final int targetId;
  final int? commentId;
  final String preview;
  final bool read;
  final DateTime? createdAt;
  final PostAuthor actor;

  NotificationItem({
    required this.id,
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.commentId,
    required this.preview,
    required this.read,
    required this.createdAt,
    required this.actor,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: _int(j['id']),
        type: _str(j['type']),
        targetType: _str(j['targetType']),
        targetId: _int(j['targetId']),
        commentId: j['commentId'] == null ? null : _int(j['commentId']),
        preview: _str(j['preview']),
        read: _bool(j['read']),
        createdAt: _date(j['createdAt']),
        actor: PostAuthor.fromJson(
          (j['actor'] as Map<String, dynamic>?) ?? const {},
        ),
      );

  /// 「XX 赞了你的评论」等动作文案
  String get actionText => switch (type) {
        'like_comment' => '赞了你的评论',
        'reply_comment' => '回复了你的评论',
        'like_post' => '赞了你的动态',
        'comment_post' => '评论了你的动态',
        _ => '有新消息',
      };
}

/// 用户主页（公开）
class UserProfile {
  final int id;
  final String nickname;
  final String avatarIcon;
  final String role;
  final DateTime? createdAt;
  final int posts;
  final int likes;
  final bool isSelf;

  UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarIcon,
    required this.role,
    required this.createdAt,
    required this.posts,
    required this.likes,
    required this.isSelf,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    final u = (j['user'] as Map<String, dynamic>?) ?? const {};
    final s = (j['stats'] as Map<String, dynamic>?) ?? const {};
    return UserProfile(
      id: _int(u['id']),
      nickname: _str(u['nickname']),
      avatarIcon: _str(u['avatarIcon']),
      role: _str(u['role']),
      createdAt: _date(u['createdAt']),
      posts: _int(s['posts']),
      likes: _int(s['likes']),
      isSelf: _bool(j['isSelf']),
    );
  }
}

class TeamDetail {
  final Team team;
  final List<Employee> employees;
  final List<Comment> comments;

  TeamDetail(this.team, this.employees, this.comments);
}

class EmployeeDetail {
  final Employee employee;
  final Team team;
  final List<Comment> comments;

  /// 在需求中的表现（需求维度评分，不含全局分）
  final List<NeedMemberScore> needScores;

  EmployeeDetail(this.employee, this.team, this.comments,
      {this.needScores = const []});
}

class NeedDetail {
  final Need need;
  final List<Comment> comments;

  NeedDetail(this.need, this.comments);
}

class RatingAction {
  final double score;
  final int count;
  final List<double> dist;
  final bool updated;

  RatingAction({
    required this.score,
    required this.count,
    required this.dist,
    required this.updated,
  });

  factory RatingAction.fromJson(Map<String, dynamic> j) => RatingAction(
        score: _num(j['score']).toDouble(),
        count: _int(j['count']),
        dist: _dist(j['dist']),
        updated: _bool(j['updated']),
      );
}

class MyRating {
  final String targetType;
  final int targetId;
  final int score;
  final String name;
  final String? iconKey;
  final String iconKind;
  final String color1;
  final String color2;
  final String sub;
  final DateTime? updatedAt;

  MyRating({
    required this.targetType,
    required this.targetId,
    required this.score,
    required this.name,
    required this.iconKey,
    required this.iconKind,
    required this.color1,
    required this.color2,
    required this.sub,
    required this.updatedAt,
  });

  factory MyRating.fromJson(Map<String, dynamic> j) => MyRating(
        targetType: _str(j['targetType']),
        targetId: _int(j['targetId']),
        score: _int(j['score']),
        name: _str(j['name']),
        iconKey: j['iconKey'] == null ? null : _str(j['iconKey']),
        iconKind: _str(j['iconKind']),
        color1: _str(j['color1']),
        color2: _str(j['color2']),
        sub: _str(j['sub']),
        updatedAt: _date(j['updatedAt']),
      );
}

/// 相对时间：刚刚 / x 分钟前 / x 小时前 / 昨天 / x 天前 / 日期
String timeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays == 1) return '昨天';
  if (diff.inDays < 30) return '${diff.inDays} 天前';
  return '${time.year}/${time.month}/${time.day}';
}
