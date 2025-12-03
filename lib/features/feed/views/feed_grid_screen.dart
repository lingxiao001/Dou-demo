import 'package:douyin_demo/features/feed/widgets/video_card.dart';
import 'package:douyin_demo/features/viewer/views/viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/features/feed/viewmodels/feed_grid_view_model.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/services.dart';

class FeedGridScreen extends ConsumerStatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const FeedGridScreen({super.key, this.onSwitchTab});

  @override
  ConsumerState<FeedGridScreen> createState() => _FeedGridScreenState();
}

class _FeedGridScreenState extends ConsumerState<FeedGridScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedGridViewModelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('$err')),
        data: (posts) {
          final isAndroid = Theme.of(context).platform == TargetPlatform.android;
          if (!isAndroid) {
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
                      Navigator.of(context)
                          .push<int>(
                        MaterialPageRoute(
                          builder: (_) => ViewerScreen(
                            posts: posts,
                            initialIndex: index,
                          ),
                        ),
                      )
                          .then((value) {
                        if (value != null && widget.onSwitchTab != null) {
                          widget.onSwitchTab!(value);
                        }
                      });
                    },
                  );
                },
              );
            });
          }
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _buildNativePosts(posts),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final nativePosts = snapshot.data ?? const [];
              return AndroidView(
                viewType: 'native-feed-view',
                creationParams: {
                  'columns': 2,
                  'posts': nativePosts,
                },
                creationParamsCodec: const StandardMessageCodec(),
                onPlatformViewCreated: (id) {
                  final events = EventChannel('com.example.douyin_demo/native_feed_events_$id');
                  events.receiveBroadcastStream().listen((event) {
                    if (event is Map && event['type'] == 'onItemClick') {
                      final index = event['index'] as int? ?? 0;
                      Navigator.of(context)
                          .push<int>(
                        MaterialPageRoute(
                          builder: (_) => ViewerScreen(
                            posts: posts,
                            initialIndex: index,
                          ),
                        ),
                      )
                          .then((value) {
                        if (value != null && widget.onSwitchTab != null) {
                          widget.onSwitchTab!(value);
                        }
                      });
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buildNativePosts(List<dynamic> posts) async {
    final service = ThumbnailCacheService();
    final futures = posts.map((p) async {
      String? path;
      try {
        final f = await service.getThumbnail(p.videoUrl);
        path = f.path;
      } catch (_) {}
      return {
        'id': p.id,
        'title': p.title,
        'likeCount': p.likeCount,
        'authorNickname': p.author.nickname,
        'coverPath': path,
      };
    }).toList();
    return await Future.wait(futures);
  }
}
