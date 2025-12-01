import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:douyin_demo/common/services/web_thumbnail_service_stub.dart'
    if (dart.library.html) 'package:douyin_demo/common/services/web_thumbnail_service.dart';

class VideoCard extends StatelessWidget {
  final VideoPost videoPost;
  final VoidCallback? onTap; // 添加点击回调

  const VideoCard({
    super.key,
    required this.videoPost,
    this.onTap,
  });

  String _formatLikes(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Container + Decoration 实现卡片阴影和背景
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0), // 统一圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // 使用 ClipRRect 裁剪点击水波纹和图片圆角
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap, // 支持点击事件
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. 图片区域 (保持 3:4 比例) ---
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: kIsWeb
                      ? FutureBuilder<Uint8List?>(
                          future: generateThumbnail(videoPost.videoUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                              return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity);
                            }
                            return Container(
                              color: Colors.grey.shade100,
                              alignment: Alignment.center,
                              child: snapshot.hasError
                                  ? Icon(Icons.broken_image, color: Colors.grey.shade400)
                                  : SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
                                    ),
                            );
                          },
                        )
                      : FutureBuilder<File>(
                          future: ThumbnailCacheService().getThumbnail(videoPost.videoUrl),
                          builder: (context, snapshot) {
                            Widget image;
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              image = Image.file(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              );
                            } else {
                              image = Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: snapshot.hasError
                                    ? Icon(Icons.broken_image, color: Colors.grey.shade400)
                                    : SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade400),
                                      ),
                              );
                            }
                            return image;
                          },
                        ),
                ),

                // --- 2. 内容区域 (添加 Padding 防止贴边) ---
                Padding(
                  padding: const EdgeInsets.all(8.0), // 上下左右留白
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        videoPost.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14, //稍微调小一点，显得精致
                          height: 1.3,
                          fontWeight: FontWeight.w600, // 半粗体
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 6), // 标题和作者栏的间距

                      // 作者与点赞行
                      Row(
                        children: [
                          // 头像
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200, width: 1),
                            ),
                            child: CircleAvatar(
                              radius: 9, // 稍微调小
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: NetworkImage(videoPost.author.avatarUrl),
                              onBackgroundImageError: (_, __) {},
                              child: videoPost.author.avatarUrl.isEmpty
                                  ? const Icon(Icons.person, size: 12, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // 作者名
                          Expanded(
                            child: Text(
                              videoPost.author.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12
                              ),
                            ),
                          ),

                          // 点赞图标
                          Icon(
                            videoPost.isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                            size: 14,
                            color: videoPost.isLiked ? const Color(0xFFFF2C55) : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),

                          // 点赞数
                          Text(
                            _formatLikes(videoPost.likeCount),
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
