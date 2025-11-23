import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/features/viewer/viewmodels/viewer_view_model.dart';
import 'package:douyin_demo/features/viewer/widgets/tiktok_video_page.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewerScreen extends ConsumerStatefulWidget {
  final List<VideoPost>? posts;
  final int initialIndex;

  const ViewerScreen({super.key, this.posts, this.initialIndex = 0});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
  late final PageController _pageController;
  double _dragX = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(viewerPostsProvider(widget.posts));
    final currentIndex = ref.watch(viewerIndexProvider(widget.initialIndex));
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          _dragX = 0.0;
        },
        onHorizontalDragUpdate: (details) {
          _dragX += details.delta.dx;
        },
        onHorizontalDragEnd: (details) {
          final vx = details.velocity.pixelsPerSecond.dx;
          if (_dragX < -80 || vx < -500) {
            Navigator.of(context).pop(3);
          } else if (_dragX > 80 || vx > 500) {
            Navigator.of(context).pop(1);
          }
        },
        child: postsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('$err', style: const TextStyle(color: Colors.white))),
          data: (posts) {
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                allowImplicitScrolling: true,
                itemCount: posts.length,
                onPageChanged: (index) {
                  ref.read(viewerIndexProvider(widget.initialIndex).notifier).set(index);
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
                  final active = index == currentIndex;
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
    ),
    );
  }
}
