package com.example.douyin_try_native

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.StaggeredGridLayoutManager //双瀑布流 





class FeedFragment : Fragment() {

    private var dataList: List<VideoItem> = emptyList()
    private var sharedPool: RecyclerView.RecycledViewPool? = null   // 共享的 ViewPool

    // Using a simple setter pattern for this demo
    fun setData(data: List<VideoItem>) {
        this.dataList = data
    }

    fun setRecycledViewPool(pool: RecyclerView.RecycledViewPool) { // 设置共享的 ViewPool
        this.sharedPool = pool
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        return inflater.inflate(R.layout.fragment_feed, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val recyclerView = view.findViewById<RecyclerView>(R.id.recycler_view)

        // Staggered Layout Manager
        val layoutManager = StaggeredGridLayoutManager(2, StaggeredGridLayoutManager.VERTICAL)
        layoutManager.gapStrategy = StaggeredGridLayoutManager.GAP_HANDLING_NONE
        recyclerView.layoutManager = layoutManager

        // Set Shared Pool
        sharedPool?.let {
            recyclerView.setRecycledViewPool(it)
        }

        // Adapter
        val adapter = FeedAdapter(dataList)
        recyclerView.adapter = adapter
    }
}
