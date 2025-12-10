package com.example.douyin_demo

import android.content.Intent
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

interface RecycledViewPoolProvider {
  val sharedPool: RecyclerView.RecycledViewPool
}

class NativeHomeActivity : AppCompatActivity(), RecycledViewPoolProvider {

  override val sharedPool = RecyclerView.RecycledViewPool().apply {
    // 默认 viewType = 0，为了快速滑动，将缓存池大小增加到 18
    setMaxRecycledViews(0, 18)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)
    // 初始化 ViewPager2 和 TabLayout
    val viewPager = findViewById<ViewPager2>(R.id.view_pager)
    val tabLayout = findViewById<TabLayout>(R.id.tab_layout)


    // 设置 ViewPager2 的 Adapter
    val adapter = object : FragmentStateAdapter(this) {
      override fun getItemCount(): Int = 4
        //这里4个页面用的都是 NativeFeedFragment
      override fun createFragment(position: Int): androidx.fragment.app.Fragment {
        val f = NativeFeedFragment()
        f.arguments = Bundle().apply { putInt("category", position) }
        return f
      }
    }
    viewPager.adapter = adapter
    viewPager.offscreenPageLimit = 1
    viewPager.isUserInputEnabled = true

    val titles = listOf("关注", "精选", "商城", "推荐")



    // 关联 TabLayout 和 ViewPager2
    TabLayoutMediator(tabLayout, viewPager) { tab, position ->
      tab.text = titles[position]
    }.attach()

      //这里保险地写了双向监听 确保翻页和tab导航标签同步
    tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
      override fun onTabSelected(tab: TabLayout.Tab) { viewPager.currentItem = tab.position }
      override fun onTabUnselected(tab: TabLayout.Tab) {}
      override fun onTabReselected(tab: TabLayout.Tab) {}
    })
    viewPager.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
      override fun onPageSelected(position: Int) { if (tabLayout.selectedTabPosition != position) tabLayout.getTabAt(position)?.select() }
    })

      //默认初始跳到第一页-‘精选’
    viewPager.setCurrentItem(1, false)

      //可点击下导航栏按钮进入 ‘我的’界面
    findViewById<TextView>(R.id.nav_me)?.setOnClickListener {
      startActivity(Intent(this, ProfileActivity::class.java))
    }
  }
}
