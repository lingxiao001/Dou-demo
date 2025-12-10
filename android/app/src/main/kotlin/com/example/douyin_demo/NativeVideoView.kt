package com.example.douyin_demo

import android.content.Context
import android.net.Uri
import android.view.View
import android.view.LayoutInflater
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView

//实现 PlatformViewFactory 接口，用于创建 NativeVideoView 实例。
class NativeVideoFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return NativeVideoView(context, messenger, id, args)
    }
}
//实现 PlatformView 接口，用于管理视频播放。
class NativeVideoView(
    private val context: Context,
    messenger: BinaryMessenger,//用于与 Dart 端通信
    private val viewId: Int,
    args: Any?
) : PlatformView, MethodChannel.MethodCallHandler {//实现 MethodChannel.MethodCallHandler 接口，用于处理 Dart 端的方法调用。

    private val playerView: PlayerView = LayoutInflater.from(context)
        .inflate(R.layout.native_video_view, null, false) as PlayerView
    private val player: ExoPlayer
    private val channel: MethodChannel
    //创建 ExoPlayer 实例，配置视频播放参数。
    init {
        playerView.useController = false
        val trackSelector = DefaultTrackSelector(context)
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(15000, 50000, 2500, 3000)
            .build()
        player = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .build()
        player.repeatMode = Player.REPEAT_MODE_ALL
        player.videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        playerView.player = player

        channel = MethodChannel(messenger, "com.example.douyin_demo/native_video_$viewId")
        channel.setMethodCallHandler(this)
//解析 Dart 端传递的参数，如视频 URL、自动播放、循环播放、静音等。
        if (args is Map<*, *>) {
            val url = args["url"] as? String
            val path = args["path"] as? String
            val autoPlay = (args["autoPlay"] as? Boolean) ?: true
            val loop = (args["looping"] as? Boolean) ?: true
            val muted = (args["muted"] as? Boolean) ?: false

            player.repeatMode = if (loop) Player.REPEAT_MODE_ALL else Player.REPEAT_MODE_OFF

            val item = when {
                path != null -> MediaItem.fromUri(Uri.fromFile(java.io.File(path)))
                url != null -> {
                    val uri = if (url.startsWith("assets/")) Uri.parse("asset:///" + url) else Uri.parse(url)
                    MediaItem.fromUri(uri)
                }
                else -> null
            }
            if (item != null) {
                player.setMediaItem(item)
                player.prepare()
                player.volume = if (muted) 0f else 1f
                player.playWhenReady = autoPlay
            }
        }
    }

    override fun getView(): View = playerView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        playerView.player = null
        player.release()
    }
//处理 Dart 端的方法调用，如 play、pause、setVolume 等。
    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> {
                player.playWhenReady = true
                result.success(true)
            }
            "pause" -> {
                player.playWhenReady = false
                result.success(true)
            }
            "setVolume" -> {
                val v = (call.argument<Double>("volume") ?: 1.0).toFloat()
                player.volume = v
                result.success(true)
            }
            "seekTo" -> {
                val ms = call.argument<Long>("positionMs") ?: 0L
                player.seekTo(ms)
                result.success(true)
            }
            "setUrl" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    val item = MediaItem.fromUri(Uri.parse(url))
                    player.setMediaItem(item)
                    player.prepare()
                }
                result.success(true)
            }
            "setPath" -> {
                val path = call.argument<String>("path")
                if (path != null) {
                    val item = MediaItem.fromUri(Uri.fromFile(java.io.File(path)))
                    player.setMediaItem(item)
                    player.prepare()
                }
                result.success(true)
            }
            "getPosition" -> {
                result.success(player.currentPosition)
            }
            "getDuration" -> {
                result.success(player.duration)
            }
            "isPlaying" -> {
                result.success(player.isPlaying)
            }
            "getBufferedPosition" -> {
                result.success(player.bufferedPosition)
            }
            else -> result.notImplemented()
        }
    }
}
