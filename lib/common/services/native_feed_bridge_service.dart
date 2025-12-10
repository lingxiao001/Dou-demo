import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';

class NativeFeedBridgeService {
  static final NativeFeedBridgeService _i = NativeFeedBridgeService._();
  factory NativeFeedBridgeService() => _i;
  NativeFeedBridgeService._();

  Future<File> _bridgeFile() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'native_bridge'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, 'feed_posts.json'));
  }

  Future<void> persistPosts(List<VideoPost> posts) async {
    final tcs = ThumbnailCacheService();
    final maps = <Map<String, dynamic>>[];
    for (final p0 in posts) {
      String? coverPath;
      try {
        final f = await tcs.getThumbnail(p0.videoUrl);
        coverPath = f.path;
      } catch (_) {}
      maps.add({
        'id': p0.id,
        'title': p0.title,
        'likeCount': p0.likeCount,
        'coverPath': coverPath ?? '',
        'authorNickname': p0.author.nickname,
      });
    }
    final file = await _bridgeFile();
    await file.writeAsString(jsonEncode(maps));
  }
}

