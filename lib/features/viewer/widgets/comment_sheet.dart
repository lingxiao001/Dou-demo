import 'package:douyin_demo/common/models/comment.dart';
import 'package:douyin_demo/common/models/user.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/repositories/video_repository.dart';
import 'package:flutter/material.dart';

class CommentSheet extends StatefulWidget {
  final VideoPost post;
  const CommentSheet({super.key, required this.post});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late Future<List<Comment>> _futureComments;
  final List<Comment> _comments = [];
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _futureComments = VideoRepository().fetchComments(widget.post.id);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final me = User(id: 'me', nickname: '我', avatarUrl: widget.post.author.avatarUrl);
    final c = Comment(id: DateTime.now().millisecondsSinceEpoch.toString(), postId: widget.post.id, author: me, content: text, createdAt: DateTime.now());
    setState(() {
      _comments.insert(0, c);
      _textController.clear();
    });
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '刚刚';
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    if (d.inHours < 24) return '${d.inHours}小时前';
    return '${d.inDays}天前';
  }

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(16);
    return GestureDetector(
      onTap: () {},
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: radius, topRight: radius)),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('大家都在搜：${widget.post.title}', style: const TextStyle(color: Colors.black87, fontSize: 14)),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(_comments.isEmpty ? null : _comments.length),
                          child: const Icon(Icons.close, size: 18, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('${(_comments.isEmpty ? null : _comments.length) ?? widget.post.commentCount}条评论', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<Comment>>(
                      future: _futureComments,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (_comments.isEmpty && snapshot.hasData) {
                          _comments.addAll(snapshot.data!);
                        }
                        if (_comments.isEmpty) {
                          return const Center(child: Text('暂无评论', style: TextStyle(color: Colors.black54)));
                        }
                        return ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return _CommentTile(
                              avatarUrl: c.author.avatarUrl,
                              nickname: c.author.nickname,
                              content: c.content,
                              timeText: _timeAgo(c.createdAt),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x11000000)))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F7), borderRadius: BorderRadius.circular(18)),
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                decoration: const InputDecoration(border: InputBorder.none, hintText: '说点什么...', hintStyle: TextStyle(color: Colors.black26)),
                                minLines: 1,
                                maxLines: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(horizontal: 16)),
                              child: const Text('发送', style: TextStyle(fontSize: 13, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final String avatarUrl;
  final String nickname;
  final String content;
  final String timeText;
  const _CommentTile({required this.avatarUrl, required this.nickname, required this.content, required this.timeText});

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _liked = false;
  int _likes = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.avatarUrl)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nickname, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(widget.content, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(widget.timeText, style: const TextStyle(fontSize: 12, color: Colors.black38)),
                    const SizedBox(width: 12),
                    const Text('江苏', style: TextStyle(fontSize: 12, color: Colors.black38)),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() {
                        _liked = !_liked;
                        _likes += _liked ? 1 : -1;
                      }),
                      child: Row(
                        children: [
                          Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 18, color: _liked ? Colors.red : Colors.black38),
                          const SizedBox(width: 4),
                          Text('$_likes', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {},
                      child: const Text('回复', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

