package com.example.douyin_demo
//混合开发模块
//封装给 Flutter 用




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
import com.example.douyin_demo.PlayerPool

//实现 PlatformViewFactory 接口，当 Flutter需要显示该部分 ，就会调用工厂单独create方法
class NativeVideoFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return NativeVideoView(context, messenger, id, args)
    }
}



//实现 PlatformView 接口，意味着本身就是一个View
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
        playerView.useController = false//关掉ExoPlayer默认丑陋UI

        player = PlayerPool.acquire(context)

        player.repeatMode = Player.REPEAT_MODE_ALL//重复播放
        player.videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT//完整显示,保持比例
        playerView.player = player

        channel = MethodChannel(messenger, "com.example.douyin_demo/native_video_$viewId")
        channel.setMethodCallHandler(this)

//解析 Dart 端传递的参数
        if (args is Map<*, *>) {
            val url = args["url"] as? String
            val path = args["path"] as? String
            val autoPlay = (args["autoPlay"] as? Boolean) ?: true//默认自动播
            val loop = (args["looping"] as? Boolean) ?: true//默认循环
            val muted = (args["muted"] as? Boolean) ?: false//默认不静音

            player.repeatMode = if (loop) Player.REPEAT_MODE_ALL else Player.REPEAT_MODE_OFF

            val item = when {
                path != null -> MediaItem.fromUri(Uri.fromFile(java.io.File(path)))
                //下面这个播放源设置是默认情况 读取flutter asset:/// 前缀 包资源文件
                url != null -> {
                    val uri = if (url.startsWith("assets/")) Uri.parse("asset:///" + url) else Uri.parse(url)
                    MediaItem.fromUri(uri)
                }
                else -> null
            }

            if (item != null) {
                player.setMediaItem(item)//填入视频
                player.prepare()//解码器预热
                player.volume = if (muted) 0f else 1f
                player.playWhenReady = autoPlay //if自动开播
            }
        }
    }

    override fun getView(): View = playerView

    //当 Flutter 侧的 AndroidView Widget 从 Widget 树中被移除时调用
    override fun dispose() {
        channel.setMethodCallHandler(null)
        playerView.player = null
        PlayerPool.release(player)
    }


//这部分属于‘遥控器’ ：把flutter侧接受指令 映射为 player操作
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
            "seekTo" -> { //转跳到xx毫秒
                val ms = call.argument<Long>("positionMs") ?: 0L
                player.seekTo(ms)
                result.success(true)
            }

            //todo 从view里抽出来 ，复用player内核
            //未完成的优化 -- 可实现同个player，下滑视频不销毁 ，保持NativeVideoView存活 ，只更新 URL，而不是销毁重建。
            "setUrl" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    val uri = if (url.startsWith("assets/")) Uri.parse("asset:///" + url) else Uri.parse(url)
                    val item = MediaItem.fromUri(uri)
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

            //状态查询指令
            "getPosition" -> {//返回当前毫秒
                result.success(player.currentPosition)
            }
            "getDuration" -> {//返回总时长
                result.success(player.duration)
            }
            "isPlaying" -> {
                result.success(player.isPlaying)
            }
            "getBufferedPosition" -> {//返回缓冲进度
                result.success(player.bufferedPosition)
            }
            else -> result.notImplemented()
        }
    }
}
