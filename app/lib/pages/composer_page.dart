import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../core/api.dart';
import '../core/image_compress.dart';
import '../core/state.dart';
import '../core/theme.dart';
import '../core/ui_icons.dart';
import '../widgets/common.dart';
import '../widgets/cover.dart';

class ComposerPage extends StatefulWidget {
  const ComposerPage({super.key});

  @override
  State<ComposerPage> createState() => _ComposerPageState();
}

class _ComposerPageState extends State<ComposerPage> {
  final _ctrl = TextEditingController();
  final _picker = ImagePicker();
  final List<Uint8List> _images = [];
  bool _publishing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_images.length >= 4) {
      showToast(context, '最多上传 4 张图片');
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (file == null) return;
      final raw = await file.readAsBytes();
      if (raw.length > 25 * 1024 * 1024) {
        if (mounted) showToast(context, '图片过大，请换一张');
        return;
      }
      final small = await compute(compressImage, raw);
      if (!mounted) return;
      setState(() => _images.add(small));
    } catch (_) {
      if (mounted) showToast(context, '选择图片失败，请重试');
    }
  }

  Future<void> _publish() async {
    if (_publishing) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      showToast(context, '说点什么吧');
      return;
    }
    setState(() => _publishing = true);
    try {
      final images = _images
          .map((b) => 'data:image/jpeg;base64,${base64Encode(b)}')
          .toList();
      await AppScope.of(context).api.createPost(
            content: text,
            images: images,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LpColors.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: LpAppBar(
          title: '发布动态',
          leading: IconBtn(
            Ui.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            GestureDetector(
              onTap: _publishing ? null : _publish,
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                decoration: BoxDecoration(
                  color: c.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: _publishing
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '发布',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: kShadowLight,
            ),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              maxLength: 500,
              maxLines: 9,
              minLines: 6,
              style: TextStyle(fontSize: 15, height: 1.65, color: c.text1),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '分享此刻的想法…',
                hintStyle: TextStyle(fontSize: 15, color: c.text3),
                counterStyle: TextStyle(fontSize: 10.5, color: c.text3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '添加图片（可选，最多 4 张，自动压缩）',
            style: TextStyle(fontSize: 12, color: c.text2),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _images.length; i++)
                _thumb(c, i),
              if (_images.length < 4)
                GestureDetector(
                  onTap: _pick,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgIcon(Ui.image, size: 22, color: c.text3),
                        const SizedBox(height: 5),
                        Text(
                          '添加',
                          style: TextStyle(fontSize: 10.5, color: c.text3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '动态会进入平台广场，按点赞量与发布时间排序。请友善发言。',
            style: TextStyle(fontSize: 11, height: 1.7, color: c.text3),
          ),
        ],
      ),
    );
  }

  Widget _thumb(LpColors c, int i) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _images[i],
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: GestureDetector(
            onTap: () => setState(() => _images.removeAt(i)),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgIcon(Ui.close, size: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
