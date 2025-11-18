import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailService {
  static final Map<String, Uint8List?> _cache = {};

  static Future<Uint8List?> fromAsset(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    final data = await rootBundle.load(assetPath);
    final dir = await getTemporaryDirectory();
    final tmpPath = '${dir.path}/${assetPath.replaceAll('/', '_')}';
    final file = File(tmpPath);
    await file.writeAsBytes(data.buffer.asUint8List());
    final bytes = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
    _cache[assetPath] = bytes;
    return bytes;
  }
}