import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';

class ViewerPostsViewModel extends FamilyAsyncNotifier<List<VideoPost>, List<VideoPost>?> {
  @override
  Future<List<VideoPost>> build(List<VideoPost>? initialPosts) async {
    if (initialPosts != null) return initialPosts;
    final repo = ref.read(videoRepositoryProvider);
    return await repo.fetchVideoPosts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(videoRepositoryProvider);
      return await repo.fetchVideoPosts();
    });
  }
}

final viewerPostsProvider = AsyncNotifierProviderFamily<ViewerPostsViewModel, List<VideoPost>, List<VideoPost>?>(
  ViewerPostsViewModel.new,
);

class ViewerIndexViewModel extends FamilyNotifier<int, int> {
  @override
  int build(int initialIndex) {
    return initialIndex;
  }

  void set(int index) {
    state = index;
  }
}

final viewerIndexProvider = NotifierProviderFamily<ViewerIndexViewModel, int, int>(
  ViewerIndexViewModel.new,
);
