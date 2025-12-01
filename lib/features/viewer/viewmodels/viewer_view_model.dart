import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';

// 用于管理异步的视频数据列表，支持初始数据加载和刷新
class ViewerPostsViewModel extends FamilyAsyncNotifier<List<VideoPost>, List<VideoPost>?> {
  @override
  Future<List<VideoPost>> build(List<VideoPost>? initialPosts) async {
    if (initialPosts != null) return initialPosts; // 如果有初始现成数据，直接返回
    final repo = ref.read(videoRepositoryProvider);// 从依赖注入容器中获取视频仓库实例
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
