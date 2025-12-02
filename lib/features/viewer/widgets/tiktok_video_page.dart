import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:douyin_demo/common/models/video_post.dart';
import 'package:douyin_demo/common/services/thumbnail_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:douyin_demo/common/services/video_asset_cache_service.dart';
import 'package:douyin_demo/features/viewer/widgets/comment_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:douyin_demo/native_video_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:douyin_demo/common/LLMapi/llm_api.dart';
import 'package:douyin_demo/common/services/api_key_service.dart';

class TikTokVideoPage extends StatefulWidget {
  final VideoPost post;
  final bool active;

  const TikTokVideoPage({super.key, required this.post, required this.active});

  @override
  State<TikTokVideoPage> createState() => _TikTokVideoPageState();
}

class _TikTokVideoPageState extends State<TikTokVideoPage> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  VideoPlayerController? _webController;
  NativeVideoController? _nativeController;
  String? _localPath;
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
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  Timer? _progressTimer;
  Duration _buffered = Duration.zero;
  bool _seeking = false;

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
    if (kIsWeb) {
      final c = VideoPlayerController.asset(widget.post.videoUrl);
      await c.initialize();
      c.setLooping(true);
      _muted = true;
      c.setVolume(0.0);
      _webController = c;
      _initialized = true;
      if (widget.active && !_pausedByUser) {
        c.play();
        _isPlaying = true;
      }
      _updateRotation();
      if (mounted) setState(() {});
    } else {
      final file = await VideoAssetCacheService().getLocalFile(widget.post.videoUrl);
      _localPath = file.path;
      _initialized = true;
      if (mounted) setState(() {});
    }
  }


  @override
  void didUpdateWidget(covariant TikTokVideoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _initialized && !_pausedByUser) {
      if (kIsWeb) {
        _webController?.play();
      } else {
        _nativeController?.play();
      }
      _isPlaying = true;
    } else if (_initialized) {
      if (kIsWeb) {
        _webController?.pause();
      } else {
        _nativeController?.pause();
      }
      _isPlaying = false;
    }
    _updateRotation();
  }

  @override
  void dispose() {
    _webController?.dispose();
    _progressTimer?.cancel();
    _rotationController.dispose();
    _aiController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_initialized) return;
    if (kIsWeb) {
      if (_webController?.value.isPlaying ?? false) {
        _webController?.pause();
        _pausedByUser = true;
        _isPlaying = false;
      } else {
        _webController?.play();
        _pausedByUser = false;
        _isPlaying = true;
      }
    } else {
      if (_isPlaying) {
        _nativeController?.pause();
        _pausedByUser = true;
        _isPlaying = false;
      } else {
        _nativeController?.play();
        _pausedByUser = false;
        _isPlaying = true;
      }
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
    if (kIsWeb) {
      _webController?.setVolume(_muted ? 0.0 : 1.0);
    } else {
      _nativeController?.setVolume(_muted ? 0.0 : 1.0);
    }
    setState(() {});
  }

  void _updateRotation() {
    if (!_initialized) return;
    final playing = kIsWeb ? (_webController?.value.isPlaying ?? false) : _isPlaying;
    if (playing) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _rotationController.stop();
    }
  }

  Future<void> _onAiTap() async {
    if (!_initialized) return;
    _wasPlayingBeforeAi = kIsWeb ? (_webController?.value.isPlaying ?? false) : _isPlaying;
    if (kIsWeb) {
      _webController?.pause();
    } else {
      _nativeController?.pause();
    }
    _pausedByUser = true;
    final file = await VideoAssetCacheService().getLocalFile(widget.post.videoUrl);
    final ms = kIsWeb ? (_webController?.value.position.inMilliseconds ?? 0) : (await _nativeController?.getPosition() ?? Duration.zero).inMilliseconds;
    final bytes = await VideoThumbnail.thumbnailData(
      video: file.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: ms > 0 ? ms : 0,
      quality: 75,
    );
    if (bytes != null) {
      _aiImageBytes = bytes;
      _aiDataUrl = 'data:image/jpeg;base64,' + base64Encode(bytes);
    } else {
      _aiImageBytes = await VideoThumbnail.thumbnailData(video: file.path, imageFormat: ImageFormat.JPEG, quality: 75);
      if (_aiImageBytes != null) {
        _aiDataUrl = 'data:image/jpeg;base64,' + base64Encode(_aiImageBytes!);
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
      final r = await LLMapi().chatVision(imageUrl: _aiDataUrl!, prompt: text);
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
      if (kIsWeb) {
        _webController?.play();
      } else {
        _nativeController?.play();
      }
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
          child: kIsWeb
              ? (_initialized
                  ? FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _webController?.value.size.width ?? 0,
                        height: _webController?.value.size.height ?? 0,
                        child: _webController != null ? VideoPlayer(_webController!) : const SizedBox.shrink(),
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
                    ))
              : (_localPath != null
                  ? NativeVideoView(
                      path: _localPath,
                      autoPlay: widget.active && !_pausedByUser,
                      looping: true,
                      muted: _muted,
                      onCreated: (c) async {
                        _nativeController = c;
                        _progressTimer?.cancel();
                        _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (t) async {
                          if (!mounted || _nativeController == null) return;
                          if (_seeking) return;
                          final p = await _nativeController!.getPosition();
                          final d = await _nativeController!.getDuration();
                          final b = await _nativeController!.getBufferedPosition();
                          final playing = await _nativeController!.isPlaying();
                          setState(() {
                            _position = p;
                            _duration = d;
                            _buffered = b;
                            _isPlaying = playing;
                          });
                          _updateRotation();
                        });
                      },
                    )
                  : FutureBuilder<File?>(
                      future: _thumbFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                          return Image.file(snapshot.data!, fit: BoxFit.contain);
                        }
                        return const ColoredBox(color: Colors.black);
                      },
                    )),
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
        if (!_initialized || !(kIsWeb ? (_webController?.value.isPlaying ?? false) : _isPlaying))
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
                _ProgressBar(
                  fraction: (_duration.inMilliseconds > 0)
                      ? (_position.inMilliseconds.clamp(0, _duration.inMilliseconds) / _duration.inMilliseconds)
                      : 0.0,
                  bufferedFraction: (_duration.inMilliseconds > 0)
                      ? (_buffered.inMilliseconds.clamp(0, _duration.inMilliseconds) / _duration.inMilliseconds)
                      : null,
                  onSeek: (v) async {
                    if (kIsWeb && _webController != null && _webController!.value.duration > Duration.zero) {
                      final ms = (v * _webController!.value.duration.inMilliseconds).round();
                      _seeking = true;
                      setState(() {
                        _position = Duration(milliseconds: ms);
                      });
                      await _webController!.seekTo(Duration(milliseconds: ms));
                      _seeking = false;
                    } else if (_nativeController != null && _duration > Duration.zero) {
                      final ms = (v * _duration.inMilliseconds).round();
                      _seeking = true;
                      setState(() {
                        _position = Duration(milliseconds: ms);
                      });
                      await _nativeController!.seekTo(Duration(milliseconds: ms));
                      _seeking = false;
                    }
                  },
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

class _ProgressBar extends StatefulWidget {
  final double fraction;
  final double? bufferedFraction;
  final ValueChanged<double> onSeek;
  const _ProgressBar({required this.fraction, this.bufferedFraction, required this.onSeek});
  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragFraction;
  void _updateDrag(Offset localPos, double width) {
    final f = (localPos.dx / width).clamp(0.0, 1.0);
    setState(() {
      _dragFraction = f;
    });
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = 6.0;
      final frac = _dragFraction ?? widget.fraction;
      final bf = widget.bufferedFraction?.clamp(0.0, 1.0);
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (d) => _updateDrag(d.localPosition, w),
        onPanUpdate: (d) => _updateDrag(d.localPosition, w),
        onPanEnd: (_) {
          final f = (_dragFraction ?? widget.fraction).clamp(0.0, 1.0);
          widget.onSeek(f);
          setState(() {
            _dragFraction = null;
          });
        },
        child: SizedBox(
          height: 16,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: h,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(999)),
              ),
              if (bf != null)
                FractionallySizedBox(
                  widthFactor: bf,
                  alignment: Alignment.centerLeft,
                  child: Container(height: h, decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(999))),
                ),
              FractionallySizedBox(
                widthFactor: frac,
                alignment: Alignment.centerLeft,
                child: Container(height: h, decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(999))),
              ),
              Positioned(
                left: (w * frac).clamp(0.0, w - 1.0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: Color(0xFF7C4DFF), borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)]),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
