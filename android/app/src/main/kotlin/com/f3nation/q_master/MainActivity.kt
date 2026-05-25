package com.f3nation.q_master

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.ObjectOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.f3nation.q_master/sync"

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "urgent_sync") {
                val data = call.arguments as? Map<*, *>
                if (data != null) {
                    sendUrgentData(data)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENT", "Data must be a Map", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendUrgentData(data: Map<*, *>) {
        try {
            val baos = ByteArrayOutputStream()
            val oos = ObjectOutputStream(baos)
            oos.writeObject(data)
            val bytes = baos.toByteArray()

            // The path must match what the watch app expects (/$channelName)
            val request = PutDataRequest.create("/watch_connectivity")
            request.data = bytes
            
            // CRITICAL: setUrgent() bypasses battery-saving batching for immediate delivery
            request.setUrgent()

            Wearable.getDataClient(this).putDataItem(request)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
