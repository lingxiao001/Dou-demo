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



// RecyclerView.Adapter 接口
class FeedAdapter(private val onClick: (Int) -> Unit) : RecyclerView.Adapter<FeedVH>() {
    private var items: MutableList<FeedItem> = mutableListOf()//items为可操作列表 


    fun setItems(list: List<FeedItem>) {
        items = list.toMutableList() //存入
        notifyDataSetChanged() //刷新
    }

    fun addItems(list: List<FeedItem>) {
        val start = items.size
        items.addAll(list) //直接在现有数据的末尾追加新的一页数据
        //性能优化 - 局部刷新新插入的 
        notifyItemRangeInserted(start, list.size)
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
        //todo coil源码 ，
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
