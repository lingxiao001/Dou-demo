import 'package:cached_network_image/cached_network_image.dart';
import 'package:douyin_demo/common/models/video_post.dart';
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
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: videoPost.coverUrl,
                placeholder: (context, url) => AspectRatio(
                  aspectRatio: 3 / 4, // A more common aspect ratio for cards
                  child: Container(color: Colors.grey.shade200),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            // You can add duration here if you have it in the model
          ],
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
              backgroundImage: NetworkImage(videoPost.author.avatarUrl),
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