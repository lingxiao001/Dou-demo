import 'dart:io';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/material.dart';

class VideoCard extends StatelessWidget {
  final VideoPost videoPost;

  const VideoCard({super.key, required this.videoPost});

  String _formatLikes(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: FutureBuilder<File>(
            future: ThumbnailCacheService().getThumbnail(videoPost.videoUrl),
            builder: (context, snapshot) {
              Widget image;
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                image = Image.file(
                  snapshot.data!,
                  fit: BoxFit.cover,
                );
              } else if (snapshot.hasError) {
                print("Thumbnail generation error: ${snapshot.error}");
                image = Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error_outline),
                );
              } else {
                image = Container(
                  color: Colors.grey.shade200,
                );
              }
              return AspectRatio(
                aspectRatio: 3 / 4,
                child: image,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          videoPost.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 11,
              child: ClipOval(
                child: Image.network(
                  videoPost.author.avatarUrl,
                  fit: BoxFit.cover,
                  width: 22,
                  height: 22,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 14);
                  },
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                videoPost.author.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            Icon(
              videoPost.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: videoPost.isLiked ? Colors.red : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              _formatLikes(videoPost.likeCount),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}