package com.example.douyin_try_native

import kotlin.collections.get
//package com.example.douyin_try_native // 改成你的包名
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import coil.load
import coil.size.ViewSizeResolver

// 1. 继承 RecyclerView.Adapter 负责内部上下滑动的recyclerView
class FeedAdapter(private val dataList: List<VideoItem>) :
    RecyclerView.Adapter<FeedAdapter.MyViewHolder>() {

    // 2. 定义 ViewHolder (负责把 item_feed_card.xml 里的控件找出来)
    class MyViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val ivCover: ImageView = view.findViewById(R.id.iv_cover)
        val tvTitle: TextView = view.findViewById(R.id.tv_title)
        val tvAuthor: TextView = view.findViewById(R.id.tv_author)
    }

    // 3. 创建 ViewHolder (就像服务员拿一个新的空盘子) ，这里就是初始 实例化recyclerView里子卡片的部分
    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MyViewHolder {
        // 这里关联你写的那个卡片布局文件 item_feed_card
        val view = LayoutInflater.from(parent.context)
            .inflate(R.layout.item_feed_card, parent, false)
        return MyViewHolder(view)
    }

    // 4. 绑定数据 (把菜盛到盘子里)
    override fun onBindViewHolder(holder: MyViewHolder, position: Int) {
        val item = dataList[position]

        holder.tvTitle.text = item.title
        holder.tvAuthor.text = item.author

        
        // 设置图片 (使用 Coil 加载并降采样)
        holder.ivCover.load(item.coverResId) {
            crossfade(true)
            // 显式指定使用 ViewSizeResolver 确保根据 View 大小进行降采样，避免 OOM
            size(ViewSizeResolver(holder.ivCover))
        }
    }

    // 5. 告诉列表总共有多少个视频
    override fun getItemCount(): Int {
        return dataList.size
    }
}