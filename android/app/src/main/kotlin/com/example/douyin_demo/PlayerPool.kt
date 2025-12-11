package com.example.douyin_demo

import android.content.Context
import androidx.media3.common.Player
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector

object PlayerPool {
    private val pool: java.util.ArrayDeque<ExoPlayer> = java.util.ArrayDeque()
    private const val MAX_SIZE = 3

    @Synchronized
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
        } else {
            pool.removeFirst()
        }
    }

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

