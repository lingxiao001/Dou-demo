package com.example.douyin_try_native

// VideoItem.kt
// data class 是专门用来存数据的类
data class VideoItem(
    val title: String,      // 标题
    val author: String,     // 作者名字
    val coverResId: Int     // 封面图 (这里暂时用本地图片ID，实际开发会用网络URL)
)