package com.example.douyin_demo

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.StaggeredGridLayoutManager
import org.json.JSONArray
import java.io.File
import java.io.FileOutputStream

class NativeFeedFragment : Fragment() {
  private var items: List<FeedItem> = emptyList()

  override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
    return inflater.inflate(R.layout.fragment_feed, container, false)
  }

  override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
    super.onViewCreated(view, savedInstanceState)
    val rv = view.findViewById<RecyclerView>(R.id.recycler_view)
    val lm = StaggeredGridLayoutManager(2, StaggeredGridLayoutManager.VERTICAL)
    lm.gapStrategy = StaggeredGridLayoutManager.GAP_HANDLING_NONE
    rv.layoutManager = lm

    items = loadFeedItems()
    val adapter = FeedAdapter { index -> openFlutterViewer(index) }
    adapter.setItems(items)
    rv.adapter = adapter
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
      val coverPath = ensureThumbnail(videoUrl)
      out.add(FeedItem(id = id, title = title, likeCount = likeCount, coverPath = coverPath, authorNickname = authorNickname))
    }
    return out
  }

  private fun ensureThumbnail(videoAssetPath: String?): String {
    if (videoAssetPath.isNullOrEmpty()) return ""
    val name = File(videoAssetPath).nameWithoutExtension + ".jpg"
    val dir = File(requireContext().filesDir, "thumbnail_cache")
    if (!dir.exists()) dir.mkdirs()
    val dst = File(dir, name)
    if (dst.exists()) return dst.absolutePath

    val am = requireContext().assets
    val input = am.open("flutter_assets/$videoAssetPath")
    val tmp = File(requireContext().cacheDir, File(videoAssetPath).name)
    FileOutputStream(tmp).use { fos ->
      input.copyTo(fos)
    }
    val retriever = MediaMetadataRetriever()
    try {
      retriever.setDataSource(tmp.absolutePath)
      val bmp = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST)
      if (bmp != null) {
        val scaled = downsample(bmp, 512)
        dst.outputStream().use { os -> scaled.compress(Bitmap.CompressFormat.JPEG, 80, os) }
      }
    } catch (_: Throwable) {
    } finally {
      retriever.release()
      tmp.delete()
    }
    return dst.absolutePath
  }

  private fun downsample(b: Bitmap, targetW: Int): Bitmap {
    val w = b.width
    val h = b.height
    if (w <= targetW) return b
    val ratio = targetW.toFloat() / w
    val nh = (h * ratio).toInt()
    return Bitmap.createScaledBitmap(b, targetW, nh, true)
  }
}
