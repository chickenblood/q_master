package com.f3nation.q_master

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge support for Android 15+
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
