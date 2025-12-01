package com.example.douyin_demo

import android.os.Bundle
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2
import io.flutter.embedding.android.FlutterFragment

class MainActivity : FragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val viewPager = findViewById<ViewPager2>(R.id.viewPager)
        viewPager.adapter = object : FragmentStateAdapter(this) {
            override fun getItemCount(): Int = 2

            override fun createFragment(position: Int): Fragment {
                return when (position) {
                    0 -> {
                        // Use the cached FlutterEngine.
                        FlutterFragment.withCachedEngine("main_engine")
                            .build()
                    }
                    else -> {
                        // Placeholder for Native Fragment (e.g., Profile)
                        // For now, we can reuse FlutterFragment or create a simple native Fragment
                        // Let's create a simple dummy Native Fragment in the next step if needed
                        // or just reuse FlutterFragment for demo purposes but typically this would be native.
                        // To keep it simple and compiling, let's make the second page also Flutter for now
                        // BUT ideally this should be NativeExampleFragment()
                         FlutterFragment.createDefault()
                    }
                }
            }
        }
    }
}
