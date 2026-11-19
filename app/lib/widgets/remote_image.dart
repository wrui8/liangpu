import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../core/state.dart';
import '../core/theme.dart';

/// 通过 App 内置 CA 的 HTTP 客户端加载动态配图（系统 Image.network 不信任内部 CA）。
class RemoteImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? radius;

  const RemoteImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final api = AppScope.of(context).api;
    final c = LpColors.of(context);
    Widget child = FutureBuilder<Uint8List>(
      future: api.imageBytes(url),
      builder: (context, snap) {
        if (snap.hasError) {
          return Container(
            width: width,
            height: height,
            color: c.surface2,
            alignment: Alignment.center,
            child: Text(
              '图片加载失败',
              style: TextStyle(fontSize: 11, color: c.text3),
            ),
          );
        }
        final bytes = snap.data;
        if (bytes == null) {
          return Container(
            width: width,
            height: height,
            color: c.surface2,
            alignment: Alignment.center,
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.text3),
            ),
          );
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
        );
      },
    );
    if (radius != null) {
      child = ClipRRect(borderRadius: radius!, child: child);
    }
    return child;
  }
}

/// 全屏看图
class ImageViewerPage extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, i) => InteractiveViewer(
          maxScale: 4,
          child: SizedBox.expand(
            child: RemoteImage(url: images[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
