import 'package:douyin_demo/features/feed/widgets/video_card.dart';
import 'package:douyin_demo/features/viewer/views/viewer_screen.dart';
import 'package:flutter/material.dart';
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
    Future.microtask(() => ref.read(feedGridViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(feedGridViewModelProvider);
    // 给页面添加一个浅灰背景色，让白色卡片更明显
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: Builder(builder: (context) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null) {
            return Center(child: Text(vm.error!));
          }
          final posts = vm.posts;

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
      }),
    );
  }
}
