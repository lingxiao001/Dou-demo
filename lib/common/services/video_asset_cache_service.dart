import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoAssetCacheService {
  static final VideoAssetCacheService _instance = VideoAssetCacheService._();//单例模式--app只有一个仓库管理者
  factory VideoAssetCacheService() => _instance;
  VideoAssetCacheService._();

  Directory? _cacheDir;
  //在手机磁盘中创建一个文件夹，用于缓存视频文件
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
    if (await file.exists()) return file; // 如果文件已搬运过，直接返回
    final data = await rootBundle.load(assetPath);//从App assets中加载视频文件到内存
    //把内存中的视频文件写入到本地磁盘文件中
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