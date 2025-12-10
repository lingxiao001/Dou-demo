import org.json.JSONArray
import java.io.File
import java.nio.file.Paths
import java.util.concurrent.Executors
import kotlin.system.exitProcess
import org.jcodec.api.FrameGrab
import org.jcodec.common.io.IOUtils
import org.jcodec.common.io.NIOUtils
import org.jcodec.common.model.Picture
import org.jcodec.scale.AWTUtil
import javax.imageio.ImageIO

fun main() {
  val covergenDir = File(System.getProperty("user.dir"))
  val androidDir = covergenDir.parentFile
  val rootDir = androidDir.parentFile
  val videosJson = File(rootDir, "assets/mock/videos.json")
  if (!videosJson.exists()) {
    println("videos.json not found: ${videosJson.absolutePath}")
    exitProcess(1)
  }
  val coversDir = File(rootDir, "assets/covers")
  if (!coversDir.exists()) coversDir.mkdirs()
  val json = videosJson.readText()
  val arr = JSONArray(json)
  val items = mutableListOf<Pair<File, File>>()
  for (i in 0 until arr.length()) {
    val o = arr.getJSONObject(i)
    val videoUrl = o.optString("videoUrl")
    if (videoUrl.isNullOrEmpty()) continue
    val vPath = Paths.get(rootDir.absolutePath, videoUrl).normalize().toFile()
    val name = vPath.nameWithoutExtension + ".jpg"
    val dst = File(coversDir, name)
    items.add(vPath to dst)
  }
  val pool = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors().coerceAtMost(4))
  val futures = items.map { pair ->
    pool.submit {
      try {
        if (pair.second.exists()) return@submit
        val ch = NIOUtils.readableChannel(pair.first)
        try {
          val grab = FrameGrab.createFrameGrab(ch)
          grab.seekToSecondPrecise(0.0)
          val pic: Picture = grab.getNativeFrame()
          val img = AWTUtil.toBufferedImage(pic)
          ImageIO.write(img, "jpg", pair.second)
          println("generated: ${pair.second.name}")
        } finally {
          IOUtils.closeQuietly(ch)
        }
      } catch (e: Exception) {
        println("failed: ${pair.first.name} -> ${e.message}")
      }
    }
  }
  futures.forEach { it.get() }
  pool.shutdown()
  println("done: ${coversDir.absolutePath}")
}
