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

class ProfileActivity : AppCompatActivity() {
  private lateinit var sp: SharedPreferences

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.activity_profile)

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

class GridPlaceholderFragment : androidx.fragment.app.Fragment() {
  override fun onCreateView(inflater: android.view.LayoutInflater, container: android.view.ViewGroup?, savedInstanceState: Bundle?): android.view.View? {
    val rv = RecyclerView(requireContext())
    rv.layoutManager = GridLayoutManager(requireContext(), 3)
    rv.adapter = object : RecyclerView.Adapter<VH>() {
      override fun onCreateViewHolder(parent: android.view.ViewGroup, viewType: Int): VH {
        val v = android.view.View(parent.context)
        val size = parent.resources.displayMetrics.widthPixels / 3 - 12
        v.layoutParams = RecyclerView.LayoutParams(android.view.ViewGroup.LayoutParams.MATCH_PARENT, size)
        v.setBackgroundColor(0xFFECECEC.toInt())
        return VH(v)
      }
      override fun getItemCount(): Int = 12
      override fun onBindViewHolder(holder: VH, position: Int) {}
    }
    val pad = (12 * resources.displayMetrics.density).toInt()
    rv.setPadding(pad, pad, pad, pad)
    rv.clipToPadding = false
    return rv
  }
}

class VH(v: android.view.View) : RecyclerView.ViewHolder(v)

