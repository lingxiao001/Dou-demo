import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class NativeVideoController {
  final MethodChannel _channel;
  NativeVideoController._(this._channel);
  Future<void> play() => _channel.invokeMethod('play');
  Future<void> pause() => _channel.invokeMethod('pause');
  Future<void> setVolume(double v) => _channel.invokeMethod('setVolume', {'volume': v});
  Future<void> seekTo(Duration d) => _channel.invokeMethod('seekTo', {'positionMs': d.inMilliseconds});
  Future<void> setUrl(String url) => _channel.invokeMethod('setUrl', {'url': url});
  Future<void> setPath(String path) => _channel.invokeMethod('setPath', {'path': path});
  Future<Duration> getPosition() async {
    final v = await _channel.invokeMethod<int>('getPosition');
    return Duration(milliseconds: v ?? 0);
  }
  Future<Duration> getDuration() async {
    final v = await _channel.invokeMethod<int>('getDuration');
    return Duration(milliseconds: v ?? 0);
  }
  Future<bool> isPlaying() async {
    final v = await _channel.invokeMethod<bool>('isPlaying');
    return v ?? false;
  }
  Future<Duration> getBufferedPosition() async {
    final v = await _channel.invokeMethod<int>('getBufferedPosition');
    return Duration(milliseconds: v ?? 0);
  }
}

class NativeVideoView extends StatefulWidget {
  final String? url;
  final String? path;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final ValueChanged<NativeVideoController>? onCreated;

  const NativeVideoView({super.key, this.url, this.path, this.autoPlay = true, this.looping = true, this.muted = false, this.onCreated});

  @override
  State<NativeVideoView> createState() => _NativeVideoViewState();
}





class _NativeVideoViewState extends State<NativeVideoView> {
  NativeVideoController? _controller;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return AndroidView(
      viewType: 'native-video',//在这个位置显示一个 ID 为 native-video 的原生 View
      //该Map会作为参数传递给 Android 端的 onCreate 方法
      creationParams: {
        'url': widget.url,
        'path': widget.path,
        'autoPlay': widget.autoPlay,
        'looping': widget.looping,
        'muted': widget.muted,
      },
      onPlatformViewCreated: (id) {
        final channel = MethodChannel('com.example.douyin_demo/native_video_$id');
        _controller = NativeVideoController._(channel);
        widget.onCreated?.call(_controller!);
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}


