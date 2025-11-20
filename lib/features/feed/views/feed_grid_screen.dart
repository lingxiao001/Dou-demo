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

          return GridView.builder(
            padding: const EdgeInsets.all(10), // 统一外边距
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10, // 卡片上下间距
              crossAxisSpacing: 10, // 卡片左右间距

              // ==============================================
              // 【核心修改】解决溢出问题的关键
              // 3/4 = 0.75 (太短了，只够放图片)
              // 改为 0.58 (让卡片变长，容纳下方文字)
              // 如果文字还是溢出，可以试着改成 0.5--已经修改
              // ==============================================
              childAspectRatio: 0.50,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              // 使用我们刚才美化过的 VideoCard
              // 直接传入 onTap，让 VideoCard 内部的 InkWell 处理点击（会有水波纹效果）
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
        },
      ),
    );
  }
}