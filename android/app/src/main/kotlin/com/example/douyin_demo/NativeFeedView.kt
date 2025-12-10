package com.example.douyin_demo

import android.content.Context
import android.view.View
import android.view.LayoutInflater
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import coil.load
import coil.size.ViewSizeResolver

//这个文件写ViewHolder & 适配器

data class FeedItem(
    val id: String,
    val title: String,
    val likeCount: Int,
    val coverPath: String?,
    val authorNickname: String
)


/*
//实现 PlatformViewFactory 接口，用于创建 NativeFeedView 实例。
class NativeFeedFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return NativeFeedView(context, messenger, id, args)
    }
}
//实现 PlatformView 接口，用于管理抖音视频列表的显示和交互。
class NativeFeedView(
    private val context: Context,
    messenger: BinaryMessenger,
    private val viewId: Int,
    args: Any?
) : PlatformView, MethodChannel.MethodCallHandler {//实现 MethodChannel.MethodCallHandler 接口，用于处理 Dart 端的方法调用。

    private val recyclerView: RecyclerView = RecyclerView(context)
    private val adapter = FeedAdapter { index ->
        eventSink?.success(mapOf("type" to "onItemClick", "index" to index))
    }
    private val channel: MethodChannel = MethodChannel(messenger, "com.example.douyin_demo/native_feed_$viewId")
    private val events: EventChannel = EventChannel(messenger, "com.example.douyin_demo/native_feed_events_$viewId")
    private var eventSink: EventChannel.EventSink? = null
//解析 Dart 端传递的参数，如视频列表、列数等。
    init {
        val columns = if (args is Map<*, *>) (args["columns"] as? Int) ?: 2 else 2
        recyclerView.layoutManager = GridLayoutManager(context, columns)
        recyclerView.setHasFixedSize(true)
        recyclerView.itemAnimator = null
        recyclerView.setItemViewCacheSize(16)
        recyclerView.adapter = adapter
        channel.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(o: Any?, sink: EventChannel.EventSink) { eventSink = sink }
            override fun onCancel(o: Any?) { eventSink = null }
        })
        if (args is Map<*, *>) {
            val posts = args["posts"] as? List<*>
            if (posts != null) {
                val items = posts.mapNotNull { p ->
                    try {
                        val m = p as Map<*, *>
                        FeedItem(
                            id = (m["id"] as? String) ?: "",
                            title = (m["title"] as? String) ?: "",
                            likeCount = (m["likeCount"] as? Int) ?: 0,
                            coverPath = m["coverPath"] as? String,
                            authorNickname = (m["authorNickname"] as? String) ?: ""
                        )
                    } catch (_: Throwable) { null }
                }
                adapter.setItems(items)
            }
        }
    }
//返回 RecyclerView 实例，用于 Flutter 端显示抖音视频列表。
    override fun getView(): View = recyclerView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        eventSink = null
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setPosts" -> {
                val posts = call.argument<List<Map<String, Any>>>("posts")
                if (posts != null) {
                    val items = posts.map {
                        FeedItem(
                            id = (it["id"] as? String) ?: "",
                            title = (it["title"] as? String) ?: "",
                            likeCount = (it["likeCount"] as? Int) ?: 0,
                            coverPath = it["coverPath"] as? String,
                            authorNickname = (it["authorNickname"] as? String) ?: ""
                        )
                    }
                    adapter.setItems(items)
                }
                result.success(true)
            }
            "scrollToIndex" -> {
                val index = call.argument<Int>("index") ?: 0
                val smooth = call.argument<Boolean>("smooth") ?: true
                if (smooth) recyclerView.smoothScrollToPosition(index) else recyclerView.scrollToPosition(index)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
*/




// RecyclerView.Adapter 接口
class FeedAdapter(private val onClick: (Int) -> Unit) : RecyclerView.Adapter<FeedVH>() {
    private var items: List<FeedItem> = emptyList()
    fun setItems(list: List<FeedItem>) {
        items = list //存入
        notifyDataSetChanged() //刷新
    }


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FeedVH {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_feed_card, parent, false)
        return FeedVH(v)
    }

    override fun getItemCount(): Int = items.size


    override fun onBindViewHolder(holder: FeedVH, position: Int) {
        holder.bind(items[position])
        holder.itemView.setOnClickListener { onClick(position) } //设置为点击传出被点击视频编号
    }
}


class FeedVH(v: View) : RecyclerView.ViewHolder(v) {
    //绑定xml布局里的控件
    private val cover: ImageView = v.findViewById(R.id.cover)//封面图片
    private val title: TextView = v.findViewById(R.id.title)//视频标题
    private val author: TextView = v.findViewById(R.id.author)//作者昵称
    private val likes: TextView = v.findViewById(R.id.likes)//点赞数
    
    fun bind(item: FeedItem) {
        title.text = item.title
        author.text = item.authorNickname
        likes.text = formatLikes(item.likeCount)
        val path = item.coverPath ?: ""
        if (path.isNotEmpty()) {
            cover.load(path) {
                crossfade(true) //淡入淡出
                size(ViewSizeResolver(cover))//降采样（按需加载尺寸）
            }
        } else {
            cover.setImageDrawable(null)
        }
    }
    private fun formatLikes(count: Int): String {
        return if (count >= 10000) String.format("%.1f万", count / 10000.0) else count.toString()
    }
}
