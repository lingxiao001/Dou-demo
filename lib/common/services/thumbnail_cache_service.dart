
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailCacheService {
  // Singleton pattern to ensure a single instance
  static final ThumbnailCacheService _instance = ThumbnailCacheService._internal();
  factory ThumbnailCacheService() => _instance;
  ThumbnailCacheService._internal();

  Future<File> getThumbnail(String videoAssetPath) async {
    final videoFileName = p.basename(videoAssetPath);
    final thumbnailFileName = '${p.basenameWithoutExtension(videoFileName)}.jpg';
    
    print('[TCS] Request for thumbnail: $thumbnailFileName');

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final cacheDirectory = Directory(p.join(documentsDirectory.path, 'thumbnail_cache'));

    if (!await cacheDirectory.exists()) {
      print('[TCS] Creating cache directory: ${cacheDirectory.path}');
      await cacheDirectory.create();
    }

    final cachedThumbnailFile = File(p.join(cacheDirectory.path, thumbnailFileName));

    if (await cachedThumbnailFile.exists()) {
      print('[TCS] Cache hit for: $thumbnailFileName');
      return cachedThumbnailFile;
    }
    
    print('[TCS] Cache miss. Generating for: $thumbnailFileName');
    
    final tempDirectory = await getTemporaryDirectory();
    final tempVideoFile = File(p.join(tempDirectory.path, videoFileName));

    try {
      print('[TCS]  - Copying asset to temp file: ${tempVideoFile.path}');
      final byteData = await rootBundle.load(videoAssetPath);
      await tempVideoFile.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

      print('[TCS]  - Starting thumbnail generation via plugin');
      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: tempVideoFile.path,
        thumbnailPath: cachedThumbnailFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 80,
      );
      
      if (generatedPath == null) {
        throw Exception('Plugin returned null path for $videoAssetPath');
      }

      print('[TCS]  - Generation successful: $generatedPath');
      return cachedThumbnailFile;

    } catch (e) {
      print('[TCS] !!! Thumbnail generation FAILED for $videoFileName: $e');
      // If generation fails, delete any partial thumbnail file that might have been created.
      if (await cachedThumbnailFile.exists()) {
        await cachedThumbnailFile.delete();
      }
      rethrow; // Rethrow the exception to be caught by the FutureBuilder
    } finally {
      // Clean up the temporary video file.
      if (await tempVideoFile.exists()) {
        print('[TCS]  - Cleaning up temp file: ${tempVideoFile.path}');
        await tempVideoFile.delete();
      }
    }
  }
}
