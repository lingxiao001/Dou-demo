import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:douyin_demo/features/feed/widgets/video_card.dart';
import 'package:douyin_demo/features/viewer/views/viewer_screen.dart';
import 'package:flutter/material.dart';

class FeedGridScreen extends StatefulWidget {
  const FeedGridScreen({super.key});

  @override
  State<FeedGridScreen> createState() => _FeedGridScreenState();
}

class _FeedGridScreenState extends State<FeedGridScreen> {
  late final Future<List<VideoPost>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _futurePosts = VideoRepository().fetchVideoPosts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VideoPost>>(
      future: _futurePosts,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('暂无内容'));
        }
        final posts = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3 / 4,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ViewerScreen(
                      posts: posts,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: VideoCard(videoPost: post),
            );
          },
        );
      },
    );
  }
}