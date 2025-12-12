package com.example.douyin_demo

import android.content.Context
import androidx.media3.common.Player
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector


object PlayerPool {
    private val pool: java.util.ArrayDeque<ExoPlayer> = java.util.ArrayDeque()
    private const val MAX_SIZE = 3//3个播放器够用了

    @Synchronized//防止多线程同时调用acquire时，导致创建多个ExoPlayer
    fun acquire(context: Context): ExoPlayer {

        return if (pool.isEmpty()) {

            val appContext = context.applicationContext
            val trackSelector = DefaultTrackSelector(appContext)
            val loadControl = DefaultLoadControl.Builder()
                .setBufferDurationsMs(10000, 20000, 2000, 3000)
                .build()
            ExoPlayer.Builder(appContext)
                .setTrackSelector(trackSelector)
                .setLoadControl(loadControl)
                .build()

        } else {//如果有直接取走第一个 
            pool.removeFirst()
        }
    }
        
    //释放播放器到池子，重置洗掉状态 
    @Synchronized
    fun release(player: ExoPlayer) {
        player.playWhenReady = false
        player.stop()
        player.clearMediaItems()
        player.seekTo(0)
        player.repeatMode = Player.REPEAT_MODE_OFF
        player.volume = 1f
        if (pool.size < MAX_SIZE) {
            pool.addLast(player)
        } else {
            player.release()
        }
    }
}

