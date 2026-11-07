import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const YanzCheatApp());
}

class YanzCheatApp extends StatelessWidget {
  const YanzCheatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OREO VVIP V33',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF07060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A227),
          secondary: Color(0xFFB3121F),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= TAMPILAN JENDELA MENGAMBANG (OVERLAY) =================
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayWindow(),
    ),
  );
}

class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});
  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  bool isCheatOn = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: 220,
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0D15).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCheatOn ? Colors.green : const Color(0xFFB3121F), width: 2),
            boxShadow: [
              BoxShadow(
                color: isCheatOn ? Colors.green.withOpacity(0.5) : const Color(0xFFB3121F).withOpacity(0.5), 
                blurRadius: 15
              )
            ],
          ),
          child: Row(
            children: [
              // Ikon Api
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isCheatOn 
                      ? [Colors.green, Colors.greenAccent] 
                      : [const Color(0xFFC9A227), const Color(0xFFB3121F)]
                  ),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              
              // Teks & Status
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OREO VVIP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(
                      isCheatOn ? 'ACTIVE' : 'STANDBY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCheatOn ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Tombol Switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isCheatOn,
                  activeColor: Colors.green,
                  activeTrackColor: Colors.green.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black,
                  onChanged: (val) {
                    setState(() {
                      isCheatOn = val;
                    });
                    // Kirim data status ke aplikasi utama (kalau butuh)
                    FlutterOverlayWindow.shareData({"cheat_status": isCheatOn});
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
