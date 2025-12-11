package com.example.douyin_demo

 
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.StaggeredGridLayoutManager
import org.json.JSONArray
import java.io.File
 

class NativeFeedFragment : Fragment() {
  private var items: List<FeedItem> = emptyList()
  private var isLoading = false//锁-是否正在加载更多

  override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
    return inflater.inflate(R.layout.fragment_feed, container, false)
  }


  // 初始化 RecyclerView
  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)

    val rv = view.findViewById<RecyclerView>(R.id.recycler_view)
      //交错网格--瀑布流
    val lm = StaggeredGridLayoutManager(2, StaggeredGridLayoutManager.VERTICAL)
    lm.gapStrategy = StaggeredGridLayoutManager.GAP_HANDLING_NONE
    rv.layoutManager = lm

    rv.setRecycledViewPool(RecyclerViewPoolManager.sharedPool)



    items = loadFeedItems()//拿到我所有mock数据



    val adapter = FeedAdapter { index -> 
        if (items.isNotEmpty()) {
            openFlutterViewer(index % items.size) //这里是重复用mock数据模拟，不断循环重复，index取模开视频
        }
    }
    adapter.setItems(items)
    rv.adapter = adapter



    // 无限滚动加载
    rv.addOnScrollListener(object : RecyclerView.OnScrollListener() {
        override fun onScrolled(recyclerView: RecyclerView, dx: Int, dy: Int) {
            super.onScrolled(recyclerView, dx, dy)

            if (dy > 0 && !isLoading) {
                val totalItemCount = lm.itemCount
                //拿到交错网格最底部位置 
                val lastVisibleItemPositions = lm.findLastVisibleItemPositions(null)
                val lastVisibleItemPosition = lastVisibleItemPositions.maxOrNull() ?: 0//找到最底 
                
                // 还剩4个到底就加载more 
                if (totalItemCount <= lastVisibleItemPosition + 4) {
                    isLoading = true
                    rv.post {
                        adapter.addItems(items)//重复无限加载-把手里的数据又塞回去 
                        isLoading = false
                    }
                }
            }
        }
    })
  }



    //点击进入视频内流
  private fun openFlutterViewer(index: Int) {
    val intent = io.flutter.embedding.android.FlutterActivity
      .NewEngineIntentBuilder(MainActivity::class.java)
      .initialRoute("viewer/$index")
      .build(requireContext())
    startActivity(intent)
  }




  // 读 获取列表要显示的数据
  private fun loadFeedItems(): List<FeedItem> {
      //先找缓存json
    val bridgeFile = File(requireContext().filesDir, "native_bridge/feed_posts.json")
    if (bridgeFile.exists()) {
      val txt = bridgeFile.readText()
      return parseBridgeJson(txt)
    }
      //否则降级去flutter_assets里找
    val am = requireContext().assets
    val input = am.open("flutter_assets/assets/mock/videos.json")
    val json = input.bufferedReader().use { it.readText() }
    return parseAssetsJson(json)
  }





    //把json转FeedItem对象list
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
