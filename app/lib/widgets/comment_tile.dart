import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/agent_demo.dart';
import '../core/agent_models.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../pages/login_page.dart';
import '../pages/user_profile_page.dart';
import 'agent/agent_avatar.dart';
import 'agent/agent_card_sheet.dart';
import 'agent/agent_mention_button.dart';
import 'common.dart';
import 'cover.dart';

const _palette = <List<Color>>[
  [Color(0xFF8E9BFF), Color(0xFF5B6CFF)],
  [Color(0xFFFFB36B), Color(0xFFFF7A45)],
  [Color(0xFF6BD9B5), Color(0xFF2BC48A)],
  [Color(0xFFFF9AA2), Color(0xFFF23441)],
  [Color(0xFF7FC8F8), Color(0xFF12B5CB)],
  [Color(0xFFC9A7FF), Color(0xFF8E4DFF)],
];

List<Color> colorForName(String name) {
  var h = 0;
  for (final rune in name.runes) {
    h = (h * 31 + rune) & 0x7fffffff;
  }
  return _palette[h % _palette.length];
}

Future<bool> _ensureLogin(BuildContext context) async {
  final app = AppScope.of(context);
  if (app.loggedIn) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );
  return ok == true;
}

void _openUser(BuildContext context, int userId) {
  if (userId <= 0) return;
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)),
  );
}

/// 这条评论是否由 Agent 发出（服务端 isAgent 或 userId 命中 meta）
AgentProfile? _agentFor(Comment c, AppState app) {
  final meta = app.agentMeta;
  if (meta == null) return null;
  return meta.byUserId(c.userId) ?? (c.isAgent ? meta.primary : null);
}

void _openAuthor(BuildContext context, Comment comment, AppState app) {
  final agent = _agentFor(comment, app);
  if (agent != null) {
    showAgentCard(context, agent, demo: app.agentDemoActive);
    return;
  }
  _openUser(context, comment.userId);
}

Widget _authorAvatar(Comment comment, AppState app, double size) {
  final agent = _agentFor(comment, app);
  if (agent != null) return AgentAvatar(agent: agent, size: size);
  return UserAvatar(
    svg: app.iconSvg(comment.avatarIcon),
    fallbackName: comment.user,
    size: size,
    animate: false,
  );
}

/// 点赞按钮：带初始点赞态，未登录先跳登录
class _LikeButton extends StatefulWidget {
  final int commentId;
  final int likes;
  final bool liked;
  final double iconSize;

  const _LikeButton({
    required this.commentId,
    required this.likes,
    required this.liked,
    this.iconSize = 14,
  });

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  late int _likes = widget.likes;
  late bool _liked = widget.liked;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commentId != widget.commentId ||
        oldWidget.likes != widget.likes ||
        oldWidget.liked != widget.liked) {
      _likes = widget.likes;
      _liked = widget.liked;
    }
  }

  Future<void> _tap() async {
    if (_busy) return;
    if (!await _ensureLogin(context)) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final r = await AppScope.of(context).api.likeComment(widget.commentId);
      if (!mounted) return;
      setState(() {
        _liked = r.liked;
        _likes = r.likes;
      });
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    return GestureDetector(
      onTap: _tap,
      behavior: HitTestBehavior.opaque,
      /* 加大热区，桌面端/触屏都更容易点中 */
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
        child: Row(
          children: [
            SvgIcon(
              _liked ? Ui.heartFilled : Ui.heart,
              size: widget.iconSize,
              color: _liked ? c.brand : c.text3,
            ),
            const SizedBox(width: 4),
            Text(
              '$_likes',
              style: TextStyle(
                fontSize: widget.iconSize >= 14 ? 11 : 10,
                fontWeight: _liked ? FontWeight.w700 : FontWeight.w500,
                color: _liked ? c.brand : c.text3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentTile extends StatefulWidget {
  final Comment comment;
  final bool isLast;

  /// 后端异步生成 Agent 回复时通知页面刷新评论区
  final VoidCallback? onAgentPending;

  const CommentTile({
    super.key,
    required this.comment,
    this.isLast = false,
    this.onAgentPending,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late List<Comment> _replies = [...widget.comment.replies];
  late int _replyCount = widget.comment.replyCount;
  bool _replyBusy = false;
  bool _agentTyping = false;

  @override
  void didUpdateWidget(covariant CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment) {
      _replies = [...widget.comment.replies];
      _replyCount = widget.comment.replyCount;
    }
  }

  /// [target] 可以是主评论，也可以是任意一条回复（多层级回复）
  Future<void> _replyTo(Comment target) async {
    if (_replyBusy) return;
    if (!await _ensureLogin(context)) return;
    if (!mounted) return;
    final text = await _askReply(context, target.user);
    if (text == null || !mounted) return;
    final app = AppScope.of(context);
    final agent = app.primaryAgent;
    final mentions = agent != null &&
            agent.canComment &&
            app.textMentionsAgent(text)
        ? <Map<String, dynamic>>[
            {'type': 'agent', 'agentId': agent.id},
          ]
        : null;
    setState(() => _replyBusy = true);
    try {
      final created = await app.api.replyComment(
        target.id,
        text,
        mentions: mentions,
      );
      if (!mounted) return;
      setState(() {
        _replies = [..._replies, created];
        _replyCount += 1;
      });
      final wantsAgent = agent != null && app.textMentionsAgent(text);
      if (!wantsAgent) {
        showToast(context, '回复成功');
        return;
      }
      if (!agent.canComment) {
        showToast(context, '回复成功，${agent.name} 暂未开放评论区回复');
        return;
      }
      showToast(context, '回复成功，已呼叫 ${agent.name}');
      if (app.agentDemoActive) {
        /* 预览期：本地模拟「正在输入」与 Agent 回复 */
        setState(() => _agentTyping = true);
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          final live = AppScope.of(context).primaryAgent;
          if (live == null || !live.canComment) {
            setState(() => _agentTyping = false);
            return;
          }
          final agentReply = buildDemoAgentComment(
            agent: live,
            parent: created,
            input: text,
          );
          setState(() {
            _agentTyping = false;
            _replies = [..._replies, agentReply];
            _replyCount += 1;
          });
        });
      } else {
        /* 真实模式：服务端异步生成，稍后由页面静默刷新 */
        widget.onAgentPending?.call();
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _replyBusy = false);
    }
  }

  Future<String?> _askReply(BuildContext context, String toName) async {
    final c = LpColors.of(context);
    final ctrl = TextEditingController();
    final focus = FocusNode();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        void send() {
          if (ctrl.text.trim().isEmpty) return;
          Navigator.of(ctx).pop(true);
        }

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '回复 $toName',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text1,
                  ),
                ),
                const SizedBox(height: 10),
                /* Enter 发送、Shift+Enter 换行；移动端用键盘「发送」键 */
                CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.enter): send,
                    const SingleActivator(LogicalKeyboardKey.numpadEnter): send,
                  },
                  child: TextField(
                    controller: ctrl,
                    focusNode: focus,
                    autofocus: true,
                    maxLength: 120,
                    maxLines: 4,
                    minLines: 2,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => send(),
                    style: TextStyle(fontSize: 14, color: c.text1),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.surface2,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '友善回复…（Enter 发送，Shift+Enter 换行）',
                      hintStyle: TextStyle(fontSize: 13, color: c.text3),
                      counterStyle: TextStyle(fontSize: 10, color: c.text3),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AgentMentionButton(
                    controller: ctrl,
                    focusNode: focus,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: '发送回复',
                    onTap: send,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    focus.dispose();
    if (sent != true || text.isEmpty) return null;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);
    final comment = widget.comment;
    final agent = _agentFor(comment, app);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openAuthor(context, comment, app),
            behavior: HitTestBehavior.opaque,
            child: _authorAvatar(comment, app, 36),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _openAuthor(context, comment, app),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          comment.user,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: agent == null ? c.text2 : c.text1,
                          ),
                        ),
                      ),
                    ),
                    if (agent != null) ...[
                      const SizedBox(width: 6),
                      const AgentBadge(),
                    ],
                    /* 动态评论不打分（score = 0），不显示分数标签 */
                    if (comment.score > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: c.brandSoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${comment.score} 分',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: c.brand,
                            height: 1.2,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: c.text1,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 11, color: c.text3),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _replyTo(widget.comment),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Row(
                          children: [
                            SvgIcon(Ui.community, size: 14, color: c.text3),
                            const SizedBox(width: 4),
                            Text(
                              _replyCount > 0 ? '回复 $_replyCount' : '回复',
                              style:
                                  TextStyle(fontSize: 11, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _LikeButton(
                      commentId: comment.id,
                      likes: comment.likes,
                      liked: comment.liked,
                    ),
                  ],
                ),
                if (_replies.isNotEmpty || _replyCount > 0 || _agentTyping)
                  Container(
                    margin: const EdgeInsets.only(top: 9),
                    padding:
                        const EdgeInsets.fromLTRB(11, 3, 11, 6),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in _replies)
                          _ReplyTile(
                            key: ValueKey(r.id),
                            comment: r,
                            onReply: () => _replyTo(r),
                          ),
                        if (_agentTyping && agent != null)
                          AgentTypingLine(
                            agent: agent,
                            name: agent.name,
                            avatarSize: 22,
                          ),
                        if (_replyCount > _replies.length)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                            child: Text(
                              '还有 ${_replyCount - _replies.length} 条回复',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: c.text3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;

  const _ReplyTile({
    super.key,
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);
    final agent = _agentFor(comment, app);
    final toName = comment.replyToName;
    final toId = comment.replyToUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openAuthor(context, comment, app),
            behavior: HitTestBehavior.opaque,
            child: _authorAvatar(comment, app, 26),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _openAuthor(context, comment, app),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          comment.user,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: agent == null ? c.text2 : c.text1,
                          ),
                        ),
                      ),
                    ),
                    if (agent != null) ...[
                      const SizedBox(width: 5),
                      const AgentBadge(),
                    ],
                    if (toName != null && toName.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        '回复',
                        style: TextStyle(fontSize: 10.5, color: c.text3),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: GestureDetector(
                          onTap: () {
                            if (toId == null || toId <= 0) return;
                            final target = app.agentMeta?.byUserId(toId);
                            if (target != null) {
                              showAgentCard(
                                context,
                                target,
                                demo: app.agentDemoActive,
                              );
                            } else {
                              _openUser(context, toId);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            '@$toName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: c.brand,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    _LikeButton(
                      commentId: comment.id,
                      likes: comment.likes,
                      liked: comment.liked,
                      iconSize: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    comment.text,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: c.text1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 10, color: c.text3),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onReply,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 2, 4),
                        child: Row(
                          children: [
                            SvgIcon(Ui.community, size: 12, color: c.text3),
                            const SizedBox(width: 4),
                            Text(
                              '回复',
                              style: TextStyle(fontSize: 10.5, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 评论区（亮评）
class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final String emptyText;

  /// 评论中 @ 了 Agent 且回复由服务端异步生成时，通知页面延后刷新
  final VoidCallback? onAgentPending;

  const CommentList({
    super.key,
    required this.comments,
    this.emptyText = '还没有亮评，快来抢沙发',
    this.onAgentPending,
  });

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    if (comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          emptyText,
          style: TextStyle(fontSize: 12.5, color: c.text3),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < comments.length; i++)
          CommentTile(
            key: ValueKey(comments[i].id),
            comment: comments[i],
            isLast: i == comments.length - 1,
            onAgentPending: onAgentPending,
          ),
      ],
    );
  }
}
