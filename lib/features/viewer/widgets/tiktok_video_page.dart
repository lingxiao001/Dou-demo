import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:video_player/video_player.dart';

class TikTokVideoPage extends StatefulWidget {
  final VideoPost post;
  final bool active;

  const TikTokVideoPage({super.key, required this.post, required this.active});

  @override
  State<TikTokVideoPage> createState() => _TikTokVideoPageState();
}

class _TikTokVideoPageState extends State<TikTokVideoPage> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _pausedByUser = false;
  bool _liked = false;
  Future<File?>? _thumbFuture;
  bool _showHeart = false;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.isLiked;
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
  }

  @override
  void dispose() {
    _controller.dispose();
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

  void _toggleMute() {
    _muted = !_muted;
    _controller.setVolume(_muted ? 0.0 : 1.0);
    setState(() {});
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
            onTap: _togglePlayPause,
            onDoubleTap: _toggleLike,
          ),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: _showHeart ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: const Center(
              child: Icon(Icons.favorite, color: Colors.white70, size: 96),
            ),
          ),
        ),
        if (!_initialized || !_controller.value.isPlaying)
          const Center(
            child: Icon(Icons.play_arrow_rounded, color: Colors.white70, size: 78),
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
                label: widget.post.commentCount.toString(),
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
