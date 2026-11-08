package com.yanz.cheat

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.yanz.cheat/native"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdmin::class.java)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAdminActive" -> {
                        result.success(devicePolicyManager.isAdminActive(adminComponent))
                    }
                    "requestAdmin" -> {
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                        intent.putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "Aktifkan untuk fitur keamanan perangkat"
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    "lockNow" -> {
                        if (devicePolicyManager.isAdminActive(adminComponent)) {
                            devicePolicyManager.lockNow()
                            result.success(true)
                        } else {
                            result.error("NOT_ADMIN", "Device admin belum aktif", null)
                        }
                    }
                    "isIgnoringBatteryOpt" -> {
                        val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
                        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            pm.isIgnoringBatteryOptimizations(packageName)
                        } else true
                        result.success(ok)
                    }
                    "requestIgnoreBatteryOpt" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$packageName")
                            startActivity(intent)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
