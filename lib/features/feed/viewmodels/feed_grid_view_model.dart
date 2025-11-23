import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';

class FeedGridState {
  final List<VideoPost> posts;
  final bool isLoading;
  final String? error;
  const FeedGridState({this.posts = const [], this.isLoading = false, this.error});
  FeedGridState copyWith({List<VideoPost>? posts, bool? isLoading, String? error}) {
    return FeedGridState(posts: posts ?? this.posts, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class FeedGridViewModel extends StateNotifier<FeedGridState> {
  final VideoRepository _repo;
  FeedGridViewModel(this._repo) : super(const FeedGridState());
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.fetchVideoPosts();
      state = FeedGridState(posts: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }
}

final feedGridViewModelProvider = StateNotifierProvider<FeedGridViewModel, FeedGridState>((ref) {
  final repo = ref.read(videoRepositoryProvider);
  return FeedGridViewModel(repo);
});
