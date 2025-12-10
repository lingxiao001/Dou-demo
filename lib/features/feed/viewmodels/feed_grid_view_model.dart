import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';
import 'package:douyin_demo/common/services/native_feed_bridge_service.dart';

class FeedGridViewModel extends AsyncNotifier<List<VideoPost>> {
  @override
  Future<List<VideoPost>> build() async {
    final repo = ref.read(videoRepositoryProvider);
    final list = await repo.fetchVideoPosts();
    try {
      await NativeFeedBridgeService().persistPosts(list);
    } catch (_) {}
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(videoRepositoryProvider);
      final list = await repo.fetchVideoPosts();
      try {
        await NativeFeedBridgeService().persistPosts(list);
      } catch (_) {}
      return list;
    });
  }
}

final feedGridViewModelProvider = AsyncNotifierProvider<FeedGridViewModel, List<VideoPost>>(FeedGridViewModel.new);
