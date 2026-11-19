import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../pages/login_page.dart';
import '../pages/post_detail_page.dart';
import '../pages/user_profile_page.dart';
import 'common.dart';
import 'cover.dart';
import 'remote_image.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool showUser;
  final VoidCallback? onDeleted;

  /// 详情页里复用卡片时关闭「评论」入口，避免重复打开自己
  final bool showCommentAction;

  /// 详情页里不提供删除，删除统一在列表卡片上操作
  final bool allowDelete;

  /// 是否显示右下角「查看主页 ›」；用户主页内复用卡片时关闭，避免点进同一个主页
  final bool showProfileLink;

  const PostCard({
    super.key,
    required this.post,
    this.showUser = true,
    this.onDeleted,
    this.showCommentAction = true,
    this.allowDelete = true,
    this.showProfileLink = true,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes = widget.post.likes;
  late bool _liked = widget.post.liked;
  late int _commentCount = widget.post.commentCount;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _likes = widget.post.likes;
      _liked = widget.post.liked;
      _commentCount = widget.post.commentCount;
    } else if (oldWidget.post.commentCount != widget.post.commentCount) {
      _commentCount = widget.post.commentCount;
    }
  }

  Future<void> _openComments() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          postId: widget.post.id,
          onCommentCount: (n) {
            if (mounted) setState(() => _commentCount = n);
          },
        ),
      ),
    );
  }

  Future<bool> _ensureLogin() async {
    final app = AppScope.of(context);
    if (app.loggedIn) return true;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    return ok == true;
  }

  Future<void> _like() async {
    if (_busy) return;
    if (!await _ensureLogin()) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final r = await AppScope.of(context).api.likePost(widget.post.id);
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

  Future<void> _delete() async {
    final c = LpColors.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除动态'),
        content: const Text('删除后不可恢复，配图也会一起清理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('删除', style: TextStyle(color: c.brand)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await AppScope.of(context).api.deletePost(widget.post.id);
      if (!mounted) return;
      widget.onDeleted?.call();
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  void _openProfile(int userId) {
    if (userId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfilePage(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);
    final app = AppScope.of(context);
    final post = widget.post;
    final author = post.user;
    final canDelete = author != null &&
        app.user != null &&
        (app.user!.id == author.id || app.user!.role == 'admin');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kShadowLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showUser && author != null)
            Row(
              children: [
                GestureDetector(
                  onTap: () => _openProfile(author.id),
                  behavior: HitTestBehavior.opaque,
                  child: UserAvatar(
                    svg: app.iconSvg(author.avatarIcon),
                    fallbackName: author.nickname,
                    size: 40,
                    animate: false,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openProfile(author.id),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                author.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.text1,
                                ),
                              ),
                            ),
                            if (author.role == 'admin') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: c.brandSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '管理员',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: c.brand,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeAgo(post.createdAt),
                          style: TextStyle(fontSize: 11, color: c.text3),
                        ),
                      ],
                    ),
                  ),
                ),
                if (canDelete && widget.allowDelete)
                  GestureDetector(
                    onTap: _delete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        '删除',
                        style: TextStyle(fontSize: 11.5, color: c.text3),
                      ),
                    ),
                  ),
              ],
            ),
          if (widget.showUser && author != null) const SizedBox(height: 12),
          Text(
            post.content,
            style: TextStyle(fontSize: 14.5, height: 1.7, color: c.text1),
          ),
          if (post.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            _images(post.images),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: _like,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SvgIcon(
                        _liked ? Ui.heartFilled : Ui.heart,
                        size: 16,
                        color: _liked ? c.brand : c.text3,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_likes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              _liked ? FontWeight.w700 : FontWeight.w500,
                          color: _liked ? c.brand : c.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.showCommentAction) ...[
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: _openComments,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SvgIcon(Ui.community, size: 16, color: c.text3),
                        const SizedBox(width: 5),
                        Text(
                          _commentCount > 0 ? '$_commentCount' : '评论',
                          style: TextStyle(fontSize: 12, color: c.text3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (!widget.showUser && widget.showProfileLink && author != null)
                GestureDetector(
                  onTap: () => _openProfile(author.id),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '查看主页 ›',
                      style: TextStyle(fontSize: 11.5, color: c.text3),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _images(List<String> images) {
    void open(int i) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerPage(images: images, initialIndex: i),
        ),
      );
    }

    if (images.length == 1) {
      return GestureDetector(
        onTap: () => open(0),
        child: RemoteImage(
          url: images.first,
          width: double.infinity,
          height: 210,
          radius: BorderRadius.circular(12),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, cons) {
        final w = (cons.maxWidth - 12) / 3;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < images.length; i++)
              GestureDetector(
                onTap: () => open(i),
                child: RemoteImage(
                  url: images[i],
                  width: w,
                  height: w,
                  radius: BorderRadius.circular(10),
                ),
              ),
          ],
        );
      },
    );
  }
}
