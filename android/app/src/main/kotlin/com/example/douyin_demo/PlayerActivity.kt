package com.example.douyin_demo

import android.app.Activity
import android.net.Uri
import android.os.Bundle
import androidx.media3.common.C
import androidx.media3.common.Player
import androidx.media3.common.MediaItem
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView

class PlayerActivity : Activity() {
    private lateinit var player: ExoPlayer
    private lateinit var playerView: PlayerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        playerView = PlayerView(this)
        playerView.useController = true
        setContentView(playerView)
        val trackSelector = DefaultTrackSelector(this)
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(15000, 50000, 2500, 3000)
            .build()
        //默认的 ExoPlayer 配置可能比较保守，这里加大了缓冲区（Min 15s, Max 50s）
        player = ExoPlayer.Builder(this)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .build()
        player.repeatMode = Player.REPEAT_MODE_ALL
        player.videoScalingMode = C.VIDEO_SCALING_MODE_SCALE_TO_FIT
        playerView.player = player
        val url = intent.getStringExtra("url")
        if (url != null) {
            val item = MediaItem.fromUri(Uri.parse(url))
            player.setMediaItem(item)
        }
        player.prepare()
        player.playWhenReady = true
    }
    
//当用户切后台或锁屏时，暂停播放 (playWhenReady = false)，防止后台偷跑流量或声音干扰。
    override fun onPause() {
        super.onPause()
        player.playWhenReady = false
    }
//回到页面时自动恢复播放。
    override fun onResume() {
        super.onResume()
        player.playWhenReady = true
    }
//视频解码器是硬件资源，如果不调用 release()，会导致内存泄漏，甚至导致其他 App 无法播放视频。
    override fun onDestroy() {
        playerView.player = null
        player.release()
        super.onDestroy()
    }
}
