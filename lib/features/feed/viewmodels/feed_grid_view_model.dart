import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';

class FeedGridViewModel extends AsyncNotifier<List<VideoPost>> {
  @override
  Future<List<VideoPost>> build() async {
    final repo = ref.read(videoRepositoryProvider);
    final list = await repo.fetchVideoPosts();
    return list;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(videoRepositoryProvider);
      return repo.fetchVideoPosts();
    });
  }
}

final feedGridViewModelProvider = AsyncNotifierProvider<FeedGridViewModel, List<VideoPost>>(FeedGridViewModel.new);
