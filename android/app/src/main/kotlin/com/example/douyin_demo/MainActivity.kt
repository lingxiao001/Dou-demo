package com.example.douyin_demo

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {//主活动类，用于启动 Flutter 应用
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        //全局方法通道，用于 Flutter 调用 Android 端的方法
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

            
        //在这里注册platform view工厂
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "native-video",
            NativeVideoFactory(flutterEngine.dartExecutor.binaryMessenger)
        )

//        flutterEngine.platformViewsController.registry.registerViewFactory(
//            "native-feed-view",
//            NativeFeedFactory(flutterEngine.dartExecutor.binaryMessenger)
//        )
    }
}
