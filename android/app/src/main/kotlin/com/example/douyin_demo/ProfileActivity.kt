package com.example.douyin_demo

import android.content.SharedPreferences
import android.os.Bundle
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import coil.load
import com.google.android.material.tabs.TabLayout
import com.google.android.material.tabs.TabLayoutMediator
import org.json.JSONArray
import java.io.File
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import coil.size.ViewSizeResolver

class ProfileActivity : AppCompatActivity() {
  private lateinit var sp: SharedPreferences

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_profile)
        //todo 查一下生命周期 --
    sp = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
    val nicknameV = findViewById<TextView>(R.id.nickname)
    val avatarV = findViewById<ImageView>(R.id.avatar)
    val editBtn = findViewById<Button>(R.id.btn_edit)

    val nickname = sp.getString("flutter.user_nickname", "linging") ?: "linging"
    val avatarPath = sp.getString("flutter.user_avatar_path", "") ?: ""
    nicknameV.text = nickname
    val avatarUrl = when {
      avatarPath.startsWith("file://") -> avatarPath
      avatarPath.isNotEmpty() -> avatarPath
      else -> "https://picsum.photos/seed/me/200"
    }
    avatarV.load(avatarUrl)

    editBtn.setOnClickListener {
      val input = TextView(this)
      input.text = nicknameV.text
      val et = android.widget.EditText(this)
      et.setText(nicknameV.text)

      AlertDialog.Builder(this)
        .setTitle("编辑昵称")
        .setView(et)
        .setNegativeButton("取消", null)
        .setPositiveButton("保存") { _, _ ->
          val v = et.text.toString().trim()
          if (v.isNotEmpty()) {
            sp.edit().putString("flutter.user_nickname", v).apply()
            nicknameV.text = v
          }
        }
        .show()
    }


    val tabs = findViewById<TabLayout>(R.id.tab_layout)
    val pager = findViewById<ViewPager2>(R.id.view_pager)
    pager.adapter = object : FragmentStateAdapter(this) {
      override fun getItemCount(): Int = 3

      override fun createFragment(position: Int): androidx.fragment.app.Fragment {
        return GridPlaceholderFragment()
      }
    }
    TabLayoutMediator(tabs, pager) { tab, pos ->
      tab.text = when (pos) { 0 -> "作品"; 1 -> "收藏"; else -> "喜欢" }
    }.attach()
  }
}






//模拟九宫格网格列表
class GridPlaceholderFragment : androidx.fragment.app.Fragment() {
  override fun onCreateView(inflater: android.view.LayoutInflater, container: android.view.ViewGroup?, savedInstanceState: Bundle?): android.view.View? {
    val rv = RecyclerView(requireContext())
    rv.layoutManager = GridLayoutManager(requireContext(), 3)
    
    val items = loadFeedItems()
    val adapter = ProfileGridAdapter { index -> 
        if (items.isNotEmpty()) {
            openFlutterViewer(index % items.size)
        }
    }
    adapter.setItems(items)
    rv.adapter = adapter
    
    // 移除 padding，因为我们希望图片铺满，间隔由 item layout 的 margin 控制
    rv.setPadding(0, 0, 0, 0)
    rv.clipToPadding = false
    return rv
  }

  private fun openFlutterViewer(index: Int) {
    val intent = io.flutter.embedding.android.FlutterActivity
      .NewEngineIntentBuilder(MainActivity::class.java)
      .initialRoute("viewer/$index")
      .build(requireContext())
    startActivity(intent)
  }

  private fun loadFeedItems(): List<FeedItem> {
    val bridgeFile = File(requireContext().filesDir, "native_bridge/feed_posts.json")
    if (bridgeFile.exists()) {
      val txt = bridgeFile.readText()
      return parseBridgeJson(txt)
    }
    val am = requireContext().assets
    val input = am.open("flutter_assets/assets/mock/videos.json")
    val json = input.bufferedReader().use { it.readText() }
    return parseAssetsJson(json)
  }

  private fun parseBridgeJson(json: String): List<FeedItem> {
    val arr = JSONArray(json)
    val out = mutableListOf<FeedItem>()
    for (i in 0 until arr.length()) {
      val o = arr.getJSONObject(i)
      out.add(
        FeedItem(
          id = o.optString("id"),
          title = o.optString("title"),
          likeCount = o.optInt("likeCount"),
          coverPath = o.optString("coverPath"),
          authorNickname = o.optString("authorNickname")
        )
      )
    }
    return out
  }

  private fun parseAssetsJson(json: String): List<FeedItem> {
    val arr = JSONArray(json)
    val out = mutableListOf<FeedItem>()
    for (i in 0 until arr.length()) {
      val o = arr.getJSONObject(i)
      val author = o.getJSONObject("author")
      val id = o.optString("id")
      val title = o.optString("title")
      val likeCount = o.optInt("likeCount")
      val videoUrl = o.optString("videoUrl")
      val authorNickname = author.optString("nickname")
      val name = File(videoUrl).nameWithoutExtension + ".jpg"
      val coverPath = "file:///android_asset/flutter_assets/assets/covers/$name"
      out.add(FeedItem(id = id, title = title, likeCount = likeCount, coverPath = coverPath, authorNickname = authorNickname))
    }
    return out
  }
}

class ProfileGridAdapter(private val onClick: (Int) -> Unit) : RecyclerView.Adapter<ProfileGridVH>() {
    private var items: List<FeedItem> = emptyList()
    fun setItems(list: List<FeedItem>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ProfileGridVH {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_profile_grid, parent, false)
        return ProfileGridVH(v)
    }

    override fun getItemCount(): Int = items.size

    override fun onBindViewHolder(holder: ProfileGridVH, position: Int) {
        holder.bind(items[position])
        holder.itemView.setOnClickListener { onClick(position) }
    }
}

class ProfileGridVH(v: View) : RecyclerView.ViewHolder(v) {
    private val cover: ImageView = v.findViewById(R.id.cover)
    private val likes: TextView = v.findViewById(R.id.likes)
    
    fun bind(item: FeedItem) {
        likes.text = formatLikes(item.likeCount)
        val path = item.coverPath ?: ""
        if (path.isNotEmpty()) {
            cover.load(path) {
                crossfade(true)
                size(ViewSizeResolver(cover))
            }
        } else {
            cover.setImageDrawable(null)
        }
    }
    private fun formatLikes(count: Int): String {
        return if (count >= 10000) String.format("%.1f万", count / 10000.0) else count.toString()
    }
}
