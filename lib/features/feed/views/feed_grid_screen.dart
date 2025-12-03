import 'package:douyin_demo/features/feed/widgets/video_card.dart';
import 'package:douyin_demo/features/viewer/views/viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/features/feed/viewmodels/feed_grid_view_model.dart';

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
          if (isAndroid) {
            final postMaps = posts
                .map((e) => {
                      'id': e.id,
                      'coverUrl': e.coverUrl,
                      'videoUrl': e.videoUrl,
                      'title': e.title,
                    })
                .toList();
            return AndroidView(
              viewType: 'native-feed-view',
              creationParams: {
                'posts': postMaps,
                'columns': 2,
                'autoplayPreview': true,
                'preloadCount': 6,
              },
              onPlatformViewCreated: (id) {
                const evtBase = 'com.example.douyin_demo/native_feed_events_';
                final events = EventChannel('$evtBase$id');
                events.receiveBroadcastStream().listen((e) {
                  final map = e as Map;
                  final type = map['type'] as String?;
                  if (type == 'onItemClick') {
                    final index = map['index'] as int? ?? 0;
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
              creationParamsCodec: const StandardMessageCodec(),
            );
          }
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
        },
      ),
    );
  }
}
