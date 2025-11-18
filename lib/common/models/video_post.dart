import 'package:douyin_demo/common/models/user.dart';

class VideoPost {
  final String id;
  final String coverUrl;
  final String videoUrl;
  final String title;
  final int likeCount;
  final int commentCount;
  final User author;
  final String musicTitle;
  final String musicCoverUrl;
  final bool isLiked;
  final DateTime createdAt;

  const VideoPost({
    required this.id,
    required this.coverUrl,
    required this.videoUrl,
    required this.title,
    required this.likeCount,
    required this.commentCount,
    required this.author,
    required this.musicTitle,
    required this.musicCoverUrl,
    required this.isLiked,
    required this.createdAt,
  });
}