package com.example.douyin_demo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

class NativeHomeActivity : AppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_main)

    val viewPager = findViewById<ViewPager2>(R.id.view_pager)
    val tabLayout = findViewById<TabLayout>(R.id.tab_layout)

    val adapter = object : FragmentStateAdapter(this) {
      override fun getItemCount(): Int = 4
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
    TabLayoutMediator(tabLayout, viewPager) { tab, position ->
      tab.text = titles[position]
    }.attach()
    tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
      override fun onTabSelected(tab: TabLayout.Tab) { viewPager.currentItem = tab.position }
      override fun onTabUnselected(tab: TabLayout.Tab) {}
      override fun onTabReselected(tab: TabLayout.Tab) {}
    })
    viewPager.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
      override fun onPageSelected(position: Int) { if (tabLayout.selectedTabPosition != position) tabLayout.getTabAt(position)?.select() }
    })
    viewPager.setCurrentItem(1, false)
  }
}

