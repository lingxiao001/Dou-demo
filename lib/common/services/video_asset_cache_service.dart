import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoAssetCacheService {
  static final VideoAssetCacheService _instance = VideoAssetCacheService._();
  factory VideoAssetCacheService() => _instance;
  VideoAssetCacheService._();

  Directory? _cacheDir;

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'video_cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  Future<File> getLocalFile(String assetPath) async {
    final dir = await _dir();
    final file = File(p.join(dir.path, p.basename(assetPath)));
    if (await file.exists()) return file;
    final data = await rootBundle.load(assetPath);
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    return file;
  }

  Future<void> prefetch(List<String> assetPaths) async {
    for (final a in assetPaths) {
      try {
        await getLocalFile(a);
      } catch (_) {}
    }
  }
}