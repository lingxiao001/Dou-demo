import 'dart:convert';

import 'package:douyin_demo/common/models/comment.dart';
import 'package:douyin_demo/common/models/user.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:flutter/services.dart';

class VideoRepository {
  Future<List<VideoPost>> fetchVideoPosts() async {
    // 1. 读取 JSON 文件
    final String jsonString = await rootBundle.loadString('assets/mock/videos.json');

    // 2. 解码 JSON
    final List<dynamic> jsonList = json.decode(jsonString);

    // 3. 映射为数据模型
    return jsonList.map((jsonItem) {
      final authorJson = jsonItem['author'];
      return VideoPost(
        id: jsonItem['id'],
        coverUrl: jsonItem['coverUrl'],
        videoUrl: jsonItem['videoUrl'],
        title: jsonItem['title'],
        likeCount: jsonItem['likeCount'],
        commentCount: jsonItem['commentCount'],
        author: User(
          id: authorJson['id'],
          nickname: authorJson['nickname'],
          avatarUrl: authorJson['avatarUrl'],
        ),
        musicTitle: jsonItem['musicTitle'],
        musicCoverUrl: jsonItem['musicCoverUrl'],
        isLiked: jsonItem['isLiked'],
        createdAt: DateTime.parse(jsonItem['createdAt']),
      );
    }).toList();
  }

  Future<List<Comment>> fetchComments(String postId) async {
    try {
      final String jsonString = await rootBundle.loadString('assets/mock/comments_$postId.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      return jsonList.map((jsonItem) {
        final authorJson = jsonItem['author'];
        return Comment(
          id: jsonItem['id'],
          postId: jsonItem['postId'],
          author: User(
            id: authorJson['id'],
            nickname: authorJson['nickname'],
            avatarUrl: authorJson['avatarUrl'],
          ),
          content: jsonItem['content'],
          createdAt: DateTime.parse(jsonItem['createdAt']),
        );
      }).toList();
    } catch (e) {
      // 如果没有对应的评论文件，返回一个空列表
      return [];
    }
  }
}