package com.example.douyin_demo

import android.content.Context
import android.view.View
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.StaggeredGridLayoutManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NativeFeedFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, id: Int, args: Any?): PlatformView {
        return NativeFeedView(context, messenger, id, args as? Map<*, *>)
    }
}

class NativeFeedView(
    private val context: Context,
    messenger: BinaryMessenger,
    private val viewId: Int,
    args: Map<*, *>?
) : PlatformView, MethodChannel.MethodCallHandler {

    private val recyclerView = RecyclerView(context)
    private val channel = MethodChannel(messenger, "com.example.douyin_demo/native_feed_$viewId")
    private val events = EventChannel(messenger, "com.example.douyin_demo/native_feed_events_$viewId")
    private val adapter = FeedAdapter(context)
    private var eventSink: EventChannel.EventSink? = null
    private var columns = 2
    private var autoplayPreview = true

    init {
        channel.setMethodCallHandler(this)
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) { eventSink = sink }
            override fun onCancel(arguments: Any?) { eventSink = null }
        })

        recyclerView.adapter = adapter
        val lm = StaggeredGridLayoutManager(columns, StaggeredGridLayoutManager.VERTICAL)
        recyclerView.layoutManager = lm
        recyclerView.setHasFixedSize(true)
        recyclerView.addOnScrollListener(object : RecyclerView.OnScrollListener() {
            override fun onScrolled(rv: RecyclerView, dx: Int, dy: Int) {
                val first = IntArray(columns)
                val last = IntArray(columns)
                lm.findFirstVisibleItemPositions(first)
                lm.findLastVisibleItemPositions(last)
                val f = first.minOrNull() ?: 0
                val l = last.maxOrNull() ?: 0
                eventSink?.success(mapOf("type" to "onVisibleRange", "first" to f, "last" to l))
            }
        })

        adapter.itemClick = { index -> eventSink?.success(mapOf("type" to "onItemClick", "index" to index)) }

        if (args != null) {
            val cols = args["columns"] as? Int
            val autoplay = args["autoplayPreview"] as? Boolean
            val posts = args["posts"] as? List<Map<String, Any?>>
            if (cols != null && cols > 0) {
                columns = cols
                recyclerView.layoutManager = StaggeredGridLayoutManager(columns, StaggeredGridLayoutManager.VERTICAL)
            }
            if (autoplay != null) {
                autoplayPreview = autoplay
                adapter.autoplayPreview = autoplayPreview
            }
            if (posts != null) {
                adapter.submitList(posts.map { toPost(it) })
            }
        }
    }

    override fun getView(): View = recyclerView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        eventSink = null
        recyclerView.adapter = null
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setPosts" -> {
                val posts = call.argument<List<Map<String, Any?>>>("posts")
                if (posts != null) adapter.submitList(posts.map { toPost(it) })
                result.success(true)
            }
            "appendPosts" -> {
                val posts = call.argument<List<Map<String, Any?>>>("posts")
                if (posts != null) {
                    val current = adapter.currentList.toMutableList()
                    current.addAll(posts.map { toPost(it) })
                    adapter.submitList(current)
                }
                result.success(true)
            }
            "refresh" -> {
                adapter.notifyDataSetChanged()
                result.success(true)
            }
            "scrollToIndex" -> {
                val index = call.argument<Int>("index") ?: 0
                val smooth = call.argument<Boolean>("smooth") ?: true
                if (smooth) recyclerView.smoothScrollToPosition(index) else recyclerView.scrollToPosition(index)
                result.success(true)
            }
            "setConfig" -> {
                val cols = call.argument<Int>("columns")
                val autoplay = call.argument<Boolean>("autoplayPreview")
                if (cols != null && cols > 0) {
                    columns = cols
                    recyclerView.layoutManager = StaggeredGridLayoutManager(columns, StaggeredGridLayoutManager.VERTICAL)
                }
                if (autoplay != null) {
                    autoplayPreview = autoplay
                    adapter.autoplayPreview = autoplayPreview
                }
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun toPost(m: Map<String, Any?>): Post {
        val id = (m["id"] as? String) ?: ""
        val cover = (m["coverUrl"] as? String) ?: ""
        val video = (m["videoUrl"] as? String) ?: ""
        val title = (m["title"] as? String) ?: ""
        return Post(id, cover, video, title)
    }
}

data class Post(val id: String, val coverUrl: String, val videoUrl: String, val title: String)
