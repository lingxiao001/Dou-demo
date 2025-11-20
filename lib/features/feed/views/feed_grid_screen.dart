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
    // 给页面添加一个浅灰背景色，让白色卡片更明显
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: FutureBuilder<List<VideoPost>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无内容'));
          }
          final posts = snapshot.data!;

          return LayoutBuilder(builder: (context, constraints) {
            const padding = 10.0;
            const crossSpacing = 10.0;
            const columns = 2;
            final tileWidth = (constraints.maxWidth - padding * 2 - crossSpacing) / columns;
            const contentHeight = 100.0;
            final tileHeight = tileWidth * (4 / 3) + contentHeight;
            final ratio = tileWidth / tileHeight;

            return GridView.builder(
              padding: const EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: crossSpacing,
                crossAxisSpacing: crossSpacing,
                childAspectRatio: ratio,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return VideoCard(
                  videoPost: post,
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
                );
              },
            );
          });
        },
      ),
    );
  }
}
