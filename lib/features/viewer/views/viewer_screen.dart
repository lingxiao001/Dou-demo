import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:douyin_demo/features/viewer/widgets/tiktok_video_page.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ViewerScreen extends StatefulWidget {
  final List<VideoPost>? posts;
  final int initialIndex;

  const ViewerScreen({super.key, this.posts, this.initialIndex = 0});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late Future<List<VideoPost>> _futurePosts;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _futurePosts = widget.posts != null
        ? Future.value(widget.posts)
        : VideoRepository().fetchVideoPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<List<VideoPost>>(
        future: _futurePosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('暂无视频', style: TextStyle(color: Colors.white)));
          }
          final posts = snapshot.data!;
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                allowImplicitScrolling: true,
                itemCount: posts.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (!kIsWeb) {
                    final svc = VideoAssetCacheService();
                    final toPrefetch = <String>[];
                    toPrefetch.add(posts[index].videoUrl);
                    if (index + 1 < posts.length) toPrefetch.add(posts[index + 1].videoUrl);
                    if (index - 1 >= 0) toPrefetch.add(posts[index - 1].videoUrl);
                    svc.prefetch(toPrefetch);
                  }
                },
                itemBuilder: (context, index) {
                  final active = index == _currentIndex;
                  return TikTokVideoPage(post: posts[index], active: active);
                },
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  onPressed: () {},
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: Row(
                  children: const [
                    Text('推荐', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 16),
                    Text('关注', style: TextStyle(color: Colors.white70, fontSize: 18)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
