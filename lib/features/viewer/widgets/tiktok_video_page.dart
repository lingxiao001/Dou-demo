import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:douyin_demo/features/viewer/widgets/comment_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:douyin_demo/common/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:douyin_demo/common/services/api_key_service.dart';

class TikTokVideoPage extends ConsumerStatefulWidget {
  final VideoPost post;
  final bool active;

  const TikTokVideoPage({super.key, required this.post, required this.active});

  @override
  ConsumerState<TikTokVideoPage> createState() => _TikTokVideoPageState();
}

class _TikTokVideoPageState extends ConsumerState<TikTokVideoPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _pausedByUser = false;
  bool _liked = false;
  Future<File?>? _thumbFuture;
  bool _showHeart = false;
  bool _muted = false;
  late AnimationController _rotationController;
  late int _commentCount;
  bool _showAi = false;
  bool _aiLoading = false;
  String? _aiReply;
  String? _aiDataUrl;
  Uint8List? _aiImageBytes;
  final TextEditingController _aiController = TextEditingController();
  bool _wasPlayingBeforeAi = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
    _commentCount = widget.post.commentCount;
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 8));
    _initializeController();
    _thumbFuture = ThumbnailCacheService()
        .getThumbnail(widget.post.videoUrl)
        .then<File?>((f) => f)
        .catchError((_) => null);
  }

  Future<void> _initializeController() async {
    VideoPlayerController c;
    if (kIsWeb) {
      c = VideoPlayerController.asset(widget.post.videoUrl);
      await c.initialize();
      c.setLooping(true);
      _muted = true;
      c.setVolume(0.0);
    } else {
      final file = await VideoAssetCacheService().getLocalFile(widget.post.videoUrl);
      c = VideoPlayerController.file(file);
      await c.initialize();
      c.setLooping(true);
    }
    _controller = c;
    _initialized = true;
    if (widget.active && !_pausedByUser) {
      _controller.play();
    }
    _updateRotation();
    if (mounted) setState(() {});
  }


  @override
  void didUpdateWidget(covariant TikTokVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _initialized && !_pausedByUser) {
      _controller.play();
    } else if (!widget.active && _initialized) {
      _controller.pause();
    }
    _updateRotation();
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
      _pausedByUser = true;
    } else {
      _controller.play();
      _pausedByUser = false;
    }
    setState(() {});
    _updateRotation();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _showHeart = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showHeart = false;
        });
      }
    });
  }

  Future<void> _openComments() async {
    final updated = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(post: widget.post),
    );
    if (updated != null) {
      setState(() {
        _commentCount = updated;
      });
    }
  }

  void _toggleMute() {
    _muted = !_muted;
    _controller.setVolume(_muted ? 0.0 : 1.0);
    setState(() {});
  }

  void _updateRotation() {
    if (!_initialized) return;
    if (_controller.value.isPlaying) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }
  }

  Future<void> _onAiTap() async {
    if (!_initialized) return;
    _wasPlayingBeforeAi = _controller.value.isPlaying;
    _controller.pause();
    _pausedByUser = true;
    final file = await VideoAssetCacheService().getLocalFile(widget.post.videoUrl);
    final ms = _controller.value.position.inMilliseconds;
    final bytes = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: ms > 0 ? ms : 0,
      quality: 75,
    );
    if (bytes != null) {
      _aiImageBytes = bytes;
      _aiDataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else {
      _aiImageBytes = await VideoThumbnail.thumbnailData(video: file.path, imageFormat: ImageFormat.JPEG, quality: 75);
      if (_aiImageBytes != null) {
        _aiDataUrl = 'data:image/jpeg;base64,${base64Encode(_aiImageBytes!)}';
      }
    }
    _aiReply = null;
    _aiController.clear();
    setState(() {
      _showAi = true;
    });
  }

  Future<void> _sendAi() async {
    final text = _aiController.text.trim();
    if (text.isEmpty || _aiLoading || _aiDataUrl == null) return;
    setState(() {
      _aiLoading = true;
      _aiReply = null;
    });
    try {
      final api = ref.read(llmApiProvider);
      final r = await api.chatVision(imageUrl: _aiDataUrl!, prompt: text);
      if (!mounted) return;
      setState(() {
        _aiReply = r;
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiReply = '$e';
        _aiLoading = false;
      });
    }
  }

  void _closeAi() {
    setState(() {
      _showAi = false;
    });
    if (_wasPlayingBeforeAi && _initialized) {
      _controller.play();
      _pausedByUser = false;
      _updateRotation();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        Positioned.fill(
          child: _initialized
              ? FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : FutureBuilder<File?>(
                  future: _thumbFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                      return Image.file(snapshot.data!, fit: BoxFit.contain);
                    }
                    return const ColoredBox(color: Colors.black);
                  },
                ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _togglePlayPause,
            onDoubleTap: _toggleLike,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: _showHeart ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: const Center(
                child: Icon(Icons.favorite, color: Colors.white70, size: 96),
              ),
            ),
          ),
        ),
        if (!_initialized || !_controller.value.isPlaying)
          const IgnorePointer(
            ignoring: true,
            child: Center(
              child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 78),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(widget.post.author.avatarUrl),
              ),
              const SizedBox(height: 20),
              _ActionIcon(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? Colors.red : Colors.white,
                label: widget.post.likeCount.toString(),
                onPressed: _toggleLike,
              ),
              const SizedBox(height: 20),
              _ActionIcon(
                icon: Icons.comment,
                color: Colors.white,
                label: _commentCount.toString(),
                onPressed: _openComments,
              ),
              const SizedBox(height: 20),
              _ActionIcon(
                icon: Icons.share,
                color: Colors.white,
                label: '分享',
              ),
              const SizedBox(height: 20),
              _ActionIcon(
                icon: _muted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                label: _muted ? '静音' : '音量',
                onPressed: _toggleMute,
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          bottom: 100,
          child: InkWell(
            onTap: _onAiTap,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 24,
          child: IgnorePointer(
            ignoring: true,
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: RotationTransition(
                      turns: _rotationController,
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(widget.post.author.avatarUrl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '拍同款',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '@${widget.post.author.nickname}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(4)),
                    child: const Text('关注', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.post.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 10),
              if (_initialized)
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white12,
                  ),
                ),
            ],
          ),
        ),
        if (_showAi)
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              width: 320,
              constraints: const BoxConstraints(minHeight: 220),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      const Icon(Icons.smart_toy, color: Colors.white70, size: 18),
                      const SizedBox(width: 6),
                      const Expanded(child: Text('AI', style: TextStyle(color: Colors.white, fontSize: 13))),
                      IconButton(
                        onPressed: () async {
                          final controller = TextEditingController();
                          final key = await ApiKeyService().loadArkKey() ?? '';
                          controller.text = key;
                          final v = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.black87,
                              content: TextField(
                                controller: controller,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: '输入 Ark API Key',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                                TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('保存')),
                              ],
                            ),
                          );
                          if (v != null && v.isNotEmpty) {
                            await ApiKeyService().saveArkKey(v);
                            if (mounted) setState(() {});
                          }
                        },
                        icon: const Icon(Icons.vpn_key, color: Colors.white70, size: 18),
                      ),
                      IconButton(onPressed: _closeAi, icon: const Icon(Icons.close, color: Colors.white70, size: 18)),
                    ],
                  ),
                  if (_aiImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_aiImageBytes!, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _aiController,
                      decoration: const InputDecoration(hintText: '向当前画面提问...', hintStyle: TextStyle(color: Colors.white54), filled: true, fillColor: Colors.white12, border: OutlineInputBorder()),
                      style: const TextStyle(color: Colors.white),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _aiLoading ? null : _sendAi,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                            child: _aiLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('发送', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_aiReply != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                        child: Text(_aiReply!, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onPressed;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          child: Icon(icon, color: color, size: 34),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
