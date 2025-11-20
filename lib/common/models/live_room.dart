import 'package:douyin_demo/common/models/user.dart';

class LiveRoom {
  final String id;
  final String title;
  final String coverUrl;
  final User host;
  final int viewerCount;

  const LiveRoom({required this.id, required this.title, required this.coverUrl, required this.host, required this.viewerCount});
}

