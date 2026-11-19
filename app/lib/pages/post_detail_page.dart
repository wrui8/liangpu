import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/agent_demo.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/agent/agent_mention_button.dart';
import '../widgets/comment_tile.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';
import 'login_page.dart';

/// 动态详情：动态内容 + 评论区（评论、点赞、多层级回复都复用现有体系）
class PostDetailPage extends StatefulWidget {
  final int postId;

  /// 评论数变化时通知卡片，返回列表后无需重新拉取
  final ValueChanged<int>? onCommentCount;

  const PostDetailPage({super.key, required this.postId, this.onCommentCount});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? _post;
  List<Comment> _comments = const [];
  bool _loading = true;
  String? _error;
  bool _sending = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _agentRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _agentRefresh?.cancel();
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  /// 服务端异步生成 Agent 回复，稍后静默刷新一次评论区
  void _scheduleAgentRefresh() {
    _agentRefresh?.cancel();
    _agentRefresh = Timer(const Duration(seconds: 3), () {
      if (mounted) _load(silent: true);
    });
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final d = await AppScope.of(context).api.postDetail(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = d.post;
        _comments = d.comments;
        _error = null;
      });
      widget.onCommentCount?.call(d.comments.length);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_post == null) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final app = AppScope.of(context);
    if (!app.loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _sending = true);
    try {
      final agent = app.primaryAgent;
      final mentions = agent != null &&
              agent.canComment &&
              app.textMentionsAgent(text)
          ? <Map<String, dynamic>>[
              {'type': 'agent', 'agentId': agent.id},
            ]
          : null;
      final created = await app.api.commentPost(
        widget.postId,
        text,
        mentions: mentions,
      );
      if (!mounted) return;
      _ctrl.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _comments = [..._comments, created];
        _post = _post?.copyWith(commentCount: _comments.length);
      });
      widget.onCommentCount?.call(_comments.length);

      final wantsAgent = agent != null && app.textMentionsAgent(text);
      if (!wantsAgent) {
        showToast(context, '评论成功');
        return;
      }
      if (!agent.canComment) {
        showToast(context, '评论成功，${agent.name} 暂未开放评论区回复');
        return;
      }
      showToast(context, '评论成功，已呼叫 ${agent.name}');
      if (app.agentDemoActive) {
        /* 预览期：本地模拟 Agent 回复 */
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          final live = AppScope.of(context).primaryAgent;
          if (live == null || !live.canComment) return;
          final reply = buildDemoAgentComment(
            agent: live,
            parent: created,
            input: text,
          );
          setState(() {
            _comments = [..._comments, reply];
            _post = _post?.copyWith(commentCount: _comments.length);
          });
          widget.onCommentCount?.call(_comments.length);
        });
      } else {
        _scheduleAgentRefresh();
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final post = _post;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '动态详情',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      body: _loading && post == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.2))
          : _error != null && post == null
              ? Center(
                  child: ErrorView(message: _error!, onRetry: () => _load()),
                )
              : post == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            color: c.brand,
                            onRefresh: () => _load(silent: true),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 4, bottom: 20),
                              children: [
                                PostCard(
                                  post: post,
                                  showCommentAction: false,
                                  allowDelete: false,
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    10,
                                    20,
                                    6,
                                  ),
                                  child: SectionTitle(
                                    '评论 ${_comments.length}',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    0,
                                  ),
                                  child: CommentList(
                                    comments: _comments,
                                    emptyText: '还没有评论，说两句吧',
                                    onAgentPending: _scheduleAgentRefresh,
                                  ),
                                ),
                                const FootNote('友善交流 · 评论会通知动态作者'),
                              ],
                            ),
                          ),
                        ),
                        _inputBar(c),
                      ],
                    ),
    );
  }

  Widget _inputBar(LpColors c) {
    void send() => _send();
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter): send,
                const SingleActivator(LogicalKeyboardKey.numpadEnter): send,
              },
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                maxLength: 120,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => send(),
                style: TextStyle(fontSize: 13.5, color: c.text1),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: c.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '评论动态…（Enter 发送，Shift+Enter 换行）',
                  hintStyle: TextStyle(fontSize: 12.5, color: c.text3),
                  counterText: '',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: AgentMentionButton(
              controller: _ctrl,
              focusNode: _focus,
              compact: true,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _sending ? null : send,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _sending ? 0.5 : 1,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '发送',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
