package com.example.douyin_demo

import androidx.recyclerview.widget.RecyclerView

object RecyclerViewPoolManager {
  val sharedPool: RecyclerView.RecycledViewPool by lazy {
    RecyclerView.RecycledViewPool().apply { setMaxRecycledViews(0, 18) }
  }
}
