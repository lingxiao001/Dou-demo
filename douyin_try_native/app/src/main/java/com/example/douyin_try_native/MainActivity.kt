package com.example.douyin_try_native

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator

class MainActivity : AppCompatActivity() {

    // 共享的 ViewPool
    private val viewPool = RecyclerView.RecycledViewPool()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_main)
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }



        // 1. 获取 ViewPager2 和 TabLayout
        val viewPager = findViewById<ViewPager2>(R.id.view_pager)
        val tabLayout = findViewById<TabLayout>(R.id.tab_layout)

        // 2. 设置 Adapter
        val adapter = object : FragmentStateAdapter(this) {
            override fun getItemCount(): Int = 4 // 关注, 精选, 商城, 推荐

            override fun createFragment(position: Int): androidx.fragment.app.Fragment {
                val fragment = FeedFragment()
                fragment.setRecycledViewPool(viewPool)
                
                // 根据位置设置不同的数据
                when (position) {
                    0 -> fragment.setData(generateFollowingData()) // 关注
                    1 -> fragment.setData(generateSelectedData())  // 精选
                    2 -> fragment.setData(generateMallData())      // 商城
                    3 -> fragment.setData(generateFollowingData().shuffled()) // 推荐 (随机一点)
                    else -> fragment.setData(emptyList())
                }
                return fragment
            }
        }
        viewPager.adapter = adapter
        viewPager.offscreenPageLimit = 1
        // 确保允许手势滑动
        viewPager.isUserInputEnabled = true
        
        // 3. 关联 TabLayout 和 ViewPager2
        val titles = listOf("关注", "精选", "商城", "推荐")
        TabLayoutMediator(tabLayout, viewPager) { tab, position ->
            tab.text = titles[position]
        }.attach()
        // 兜底：即使 Material 的 Mediator 出现异常，也手动同步一次
        tabLayout.addOnTabSelectedListener(object : TabLayout.OnTabSelectedListener {
            override fun onTabSelected(tab: TabLayout.Tab) {
                viewPager.currentItem = tab.position
            }
            override fun onTabUnselected(tab: TabLayout.Tab) {}
            override fun onTabReselected(tab: TabLayout.Tab) {}
        })
        viewPager.registerOnPageChangeCallback(object : ViewPager2.OnPageChangeCallback() {
            override fun onPageSelected(position: Int) {
                if (tabLayout.selectedTabPosition != position) {
                    tabLayout.getTabAt(position)?.select()
                }
            }
        })
        
        // 4. 默认选中 "精选" (索引 1)
        viewPager.setCurrentItem(1, false)
    }

    // === 数据生成逻辑 ===

    private fun generateSelectedData(): List<VideoItem> {
        val list = mutableListOf<VideoItem>()
        
        val coverResIds = listOf(
            R.drawable.img_cover_1, R.drawable.img_cover_2, R.drawable.img_cover_3,
            R.drawable.img_cover_4, R.drawable.img_cover_5, R.drawable.img_cover_6,
            R.drawable.img_cover_7, R.drawable.img_cover_8, R.drawable.img_cover_9
        )
        
        val titles = listOf(
            "快餐“扛把子”盖浇饭，为啥越来越少人吃？",
            "看他如何把一碗棒子面，吃出满汉全席的仪式感",
            "为啥全世界就中国人看片要字幕？",
            "短短的几秒钟，海藻的情绪就像坐了一场过山车。",
            "原来真有这么多人不知道这些两性知识！",
            "新斜杠青年？体验不工作生活的一天",
            "猫咪的迷惑行为大赏，笑死我了",
            "这是什么神仙地方，美哭了！",
            "学会这几招，拍照再也不尴尬"
        )
        
        val authors = listOf(
            "锤哥科普", "草民讲电影", "李砍柴", "熊熊向前冲", 
            "三多同学", "小傅不爱吃", "喵星人情报局", "旅行日记", "摄影小课堂"
        )

        for (i in 0 until 20) {
            val index = i % coverResIds.size
            list.add(VideoItem(
                title = titles.getOrElse(index) { "视频标题 $i" },
                author = authors.getOrElse(index) { "用户 $i" },
                coverResId = coverResIds[index]
            ))
        }
        return list
    }

    private fun generateFollowingData(): List<VideoItem> {
        // 关注列表：打乱顺序模拟不同内容
        val original = generateSelectedData().toMutableList()
        original.shuffle()
        return original
    }

    private fun generateMallData(): List<VideoItem> {
        val list = mutableListOf<VideoItem>()
        val coverResIds = listOf(
            R.drawable.img_cover_1, R.drawable.img_cover_2, R.drawable.img_cover_3,
            R.drawable.img_cover_4, R.drawable.img_cover_5, R.drawable.img_cover_6,
            R.drawable.img_cover_7, R.drawable.img_cover_8, R.drawable.img_cover_9
        )
        // 商品名称
        val productNames = listOf(
            "2024新款夏季纯棉短袖T恤男宽松潮流半袖", 
            "ins超火老爹鞋女2024新款百搭网面透气",
            "华为/HUAWEI Pura 70 Ultra 伸缩摄像头", 
            "雅诗兰黛小棕瓶精华液100ml",
            "三只松鼠坚果大礼包每日坚果零食", 
            "美的（Midea）电饭煲家用4L大容量",
            "耐克NIKE官方旗舰店男鞋跑步鞋", 
            "Apple iPhone 15 Pro Max (256GB)",
            "索尼（SONY）WH-1000XM5头戴式降噪耳机"
        )
        // 价格 (复用 author 字段)
        val prices = listOf(
            "¥ 59.9", "¥ 128.0", "¥ 9999.0", "¥ 680.0", 
            "¥ 129.0", "¥ 299.0", "¥ 499.0", "¥ 8999.0", "¥ 2499.0"
        )

        for (i in 0 until 20) {
            val index = i % coverResIds.size
            list.add(VideoItem(
                title = productNames.getOrElse(index) { "商品 $i" },
                author = prices.getOrElse(index) { "¥ 99.0" },
                coverResId = coverResIds[index]
            ))
        }
        return list
    }
}
