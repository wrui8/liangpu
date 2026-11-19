import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 压缩到最长边 1600、JPEG 82，保证单张 < 4MB（服务端限制）。
/// 供发布动态与发布需求共用，调用方用 compute 在后台 isolate 执行。
Uint8List compressImage(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return raw;
  var out = decoded;
  const maxSide = 1600;
  if (decoded.width > maxSide || decoded.height > maxSide) {
    out = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxSide)
        : img.copyResize(decoded, height: maxSide);
  }
  var bytes = img.encodeJpg(out, quality: 82);
  if (bytes.length > 4 * 1024 * 1024) {
    bytes = img.encodeJpg(out, quality: 60);
  }
  return bytes;
}
