import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../pages/login_page.dart';
import 'agent/agent_mention_button.dart';

const Map<int, String> kHints = {
  1: '非常糟糕',
  2: '很糟糕',
  3: '不太满意',
  4: '有点失望',
  5: '一般般',
  6: '还可以',
  7: '不错',
  8: '挺满意',
  9: '非常满意',
  10: '满分好评',
};

/// 打开打分弹层；未登录时先引导登录。返回 null 表示取消。
/// [initialScore] 为 1-10，用于点击星级后预选。
/// [scopeType]/[scopeId] 用于需求维度评分（如「在需求中的表现」），
/// 传入后本次评分只影响该需求下的成员表现分。
Future<RatingAction?> showRatingSheet(
  BuildContext context, {
  required String targetType,
  required int targetId,
  required String title,
  int initialScore = 0,
  String? scopeType,
  int? scopeId,
}) async {
  final app = AppScope.of(context);
  if (!app.loggedIn) {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok != true || !app.loggedIn) return null;
  }
  if (!context.mounted) return null;

  final result = await showModalBottomSheet<RatingAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99000000),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _RatingSheet(
        targetType: targetType,
        targetId: targetId,
        title: title,
        initialScore: initialScore,
        scopeType: scopeType,
        scopeId: scopeId,
      ),
    ),
  );
  return result;
}

class _RatingSheet extends StatefulWidget {
  final String targetType;
  final int targetId;
  final String title;
  final int initialScore;
  final String? scopeType;
  final int? scopeId;

  const _RatingSheet({
    required this.targetType,
    required this.targetId,
    required this.title,
    required this.initialScore,
    this.scopeType,
    this.scopeId,
  });

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  late int _score = widget.initialScore.clamp(0, 10);
  final TextEditingController _comment = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _focus.dispose();
    _comment.dispose();
    super.dispose();
  }

  /* 短评输入框按 Enter 直接提交（Shift+Enter 换行） */
  void _sendByEnter() {
    if (_submitting) return;
    if (_score < 1) {
      setState(() => _error = '请先选择分数');
      return;
    }
    _submit();
  }

  Future<void> _submit() async {
    if (_score < 1 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final app = AppScope.of(context);
      final content = _comment.text;
      final agent = app.primaryAgent;
      final mentions =
          agent != null && agent.canComment && app.textMentionsAgent(content)
              ? <Map<String, dynamic>>[
                  {'type': 'agent', 'agentId': agent.id},
                ]
              : null;
      final action = await app.api.rate(
        targetType: widget.targetType,
        targetId: widget.targetId,
        score: _score,
        content: content,
        mentions: mentions,
        scopeType: widget.scopeType,
        scopeId: widget.scopeId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(action);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final name = widget.title.length > 12
        ? '${widget.title.substring(0, 12)}…'
        : widget.title;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: '给 '),
                        TextSpan(
                          text: name,
                          style: TextStyle(color: c.brand),
                        ),
                        const TextSpan(text: ' 打分'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.text1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.surface2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '✕',
                      style: TextStyle(fontSize: 16, color: c.text2),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.scopeType == 'need') ...[
              const SizedBox(height: 8),
              Text(
                '本次评分只计入「${widget.title}」中的表现分，不影响全局评分与团队分',
                style: TextStyle(fontSize: 12, color: c.text3, height: 1.5),
              ),
            ],
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.22,
              children: [
                for (var i = 1; i <= 10; i++)
                  _scoreCell(i, c),
              ],
            ),
            const SizedBox(height: 13),
            SizedBox(
              height: 18,
              child: Center(
                child: Text.rich(
                  TextSpan(
                    children: _score > 0
                        ? [
                            const TextSpan(text: '你打了 '),
                            TextSpan(
                              text: '$_score',
                              style: TextStyle(
                                color: c.brand,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' 分 · ${kHints[_score]}'),
                          ]
                        : const [TextSpan(text: '点击分数开始评分')],
                  ),
                  style: TextStyle(fontSize: 12.5, color: c.text3),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter):
                          _sendByEnter,
                      const SingleActivator(LogicalKeyboardKey.numpadEnter):
                          _sendByEnter,
                    },
                    child: TextField(
                      controller: _comment,
                      focusNode: _focus,
                      maxLength: 100,
                      minLines: 3,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (_score >= 1) _submit();
                      },
                      style:
                          TextStyle(fontSize: 14, color: c.text1, height: 1.6),
                      cursorColor: c.brand,
                      decoration: InputDecoration(
                        hintText: '说说你的评价（选填，Enter 提交）',
                        hintStyle: TextStyle(fontSize: 14, color: c.text3),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding:
                            const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                    child: AgentMentionButton(
                      controller: _comment,
                      focusNode: _focus,
                      compact: true,
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(fontSize: 12, color: c.brand),
                ),
              ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _score > 0 && !_submitting ? _submit : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 48,
                decoration: BoxDecoration(
                  color: _score > 0 && !_submitting ? c.brand : c.line,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '提交评分',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _score > 0 ? Colors.white : c.text3,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCell(int n, LpColors c) {
    final on = _score == n;
    return GestureDetector(
      onTap: () => setState(() => _score = n),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: on ? c.brand : c.surface2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: on ? c.brand : c.line),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: c.brand.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : c.text1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
