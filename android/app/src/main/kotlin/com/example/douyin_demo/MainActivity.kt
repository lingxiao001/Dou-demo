package com.example.douyin_demo


import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {//主活动类，用于启动 Flutter 应用
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)


            
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
