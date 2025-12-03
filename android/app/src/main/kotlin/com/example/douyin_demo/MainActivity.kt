package com.example.douyin_demo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.douyin_demo/native")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNativePlayer" -> {
                        val url = call.argument<String>("url")
                        val intent = Intent(this, PlayerActivity::class.java)
                        if (url != null) intent.putExtra("url", url)
                        startActivity(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "native-video",
            NativeVideoFactory(flutterEngine.dartExecutor.binaryMessenger)
        )

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "native-feed-view",
            NativeFeedFactory(flutterEngine.dartExecutor.binaryMessenger)
        )
    }
}
