import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:douyin_demo/features/feed/widgets/video_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FeedGridScreen extends StatefulWidget {
  const FeedGridScreen({super.key});

  @override
  State<FeedGridScreen> createState() => _FeedGridScreenState();
}

class _FeedGridScreenState extends State<FeedGridScreen> {
  final VideoRepository _repository = VideoRepository();
  late Future<List<VideoPost>> _videoPostsFuture;

  @override
  void initState() {
    super.initState();
    _videoPostsFuture = _repository.fetchVideoPosts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VideoPost>>(
      future: _videoPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("加载失败: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("没有视频内容"));
        }

        final videoPosts = snapshot.data!;

        return MasonryGridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: videoPosts.length,
          itemBuilder: (context, index) {
            return VideoCard(videoPost: videoPosts[index]);
          },
        );
      },
    );
  }
}