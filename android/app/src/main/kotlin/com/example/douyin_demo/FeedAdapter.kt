package com.example.douyin_demo

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import android.view.View
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.ui.PlayerView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide

class FeedAdapter(private val context: Context) : ListAdapter<Post, FeedVH>(DIFF) {
    var itemClick: ((Int) -> Unit)? = null
    var autoplayPreview: Boolean = true

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FeedVH {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_feed, parent, false)
        return FeedVH(v)
    }

    override fun onBindViewHolder(holder: FeedVH, position: Int) {
        val p = getItem(position)
        holder.bind(context, p, autoplayPreview)
        holder.itemView.setOnClickListener { itemClick?.invoke(position) }
    }

    override fun onViewAttachedToWindow(holder: FeedVH) {
        super.onViewAttachedToWindow(holder)
        holder.onAttach()
    }

    override fun onViewDetachedFromWindow(holder: FeedVH) {
        super.onViewDetachedFromWindow(holder)
        holder.onDetach()
    }

    override fun onViewRecycled(holder: FeedVH) {
        super.onViewRecycled(holder)
        holder.recycle()
    }

    companion object {
        val DIFF = object : DiffUtil.ItemCallback<Post>() {
            override fun areItemsTheSame(a: Post, b: Post): Boolean = a.id == b.id
            override fun areContentsTheSame(a: Post, b: Post): Boolean = a == b
        }
    }
}

class FeedVH(v: View) : RecyclerView.ViewHolder(v) {
    private val cover: ImageView = v.findViewById(R.id.cover)
    private val playerView: PlayerView = v.findViewById(R.id.player)
    private var player: ExoPlayer? = null
    private var post: Post? = null
    private var autoplay = true
    private var listener: Player.Listener? = null

    fun bind(context: Context, p: Post, autoplayPreview: Boolean) {
        post = p
        autoplay = autoplayPreview
        Glide.with(cover).load(p.coverUrl).into(cover)
        if (player == null) {
            val trackSelector = DefaultTrackSelector(context)
            val loadControl = DefaultLoadControl.Builder().build()
            player = ExoPlayer.Builder(context).setTrackSelector(trackSelector).setLoadControl(loadControl).build()
            playerView.useController = false
            playerView.setUseTextureView(true)
            playerView.player = player
            playerView.visibility = View.INVISIBLE
            listener = object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    if (state == Player.STATE_READY) {
                        playerView.visibility = View.VISIBLE
                    }
                }
                override fun onPlayerError(error: androidx.media3.common.PlaybackException) {
                    playerView.visibility = View.INVISIBLE
                }
            }
            player?.addListener(listener!!)
        }
        val vurl = p.videoUrl
        if (vurl.isNotEmpty()) {
            val uri = if (vurl.startsWith("assets/")) android.net.Uri.parse("asset:///flutter_assets/" + vurl) else android.net.Uri.parse(vurl)
            val item = MediaItem.fromUri(uri)
            player?.setMediaItem(item)
            player?.prepare()
            player?.repeatMode = Player.REPEAT_MODE_ALL
        }
    }

    fun onAttach() {
        if (autoplay) player?.playWhenReady = true
    }

    fun onDetach() {
        player?.playWhenReady = false
    }

    fun recycle() {
        playerView.player = null
        listener?.let { player?.removeListener(it) }
        listener = null
        player?.release()
        player = null
    }
}
