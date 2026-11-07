import 'package:flutter/material.dart';

class CheatHome extends StatefulWidget {
  const CheatHome({super.key});
  @override
  State<CheatHome> createState() => _CheatHomeState();
}

class _CheatHomeState extends State<CheatHome> {
  final Map<String, bool> _features = {
    'AimBot Auto Head': true, 'AimBot Smooth': false, 'Wallhack ESP': false,
    'Speed Hack': false, 'No Recoil': true, 'Antenna Map': false,
    'Auto Headshot': false, 'Fly Hack': false, 'Infinite Ammo': false, 'Anti Ban': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFFC9A227), Color(0xFFB3121F)]),
                ),
                child: const Icon(Icons.local_fire_department, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PREMIUM CHEAT', style: TextStyle(fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold)),
                Text('Status: ACTIVE', style: TextStyle(fontSize: 10, color: Color(0xFF22C55E), letterSpacing: 2)),
              ]),
              const Spacer(),
              const Icon(Icons.verified, color: Color(0xFFC9A227)),
            ]),
          ),
          const Divider(color: Color(0xFF1E1B26), height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._features.entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0D15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E1B26)),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 14))),
                    Switch(
                      value: e.value, activeColor: const Color(0xFFC9A227),
                      onChanged: (v) => setState(() => _features[e.key] = v),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB3121F),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Cheat injected. Launch Free Fire now.'),
                      backgroundColor: Color(0xFF22C55E),
                    ));
                  },
                  child: const Text('INJECT CHEAT', style: TextStyle(fontSize: 15, letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 14),
                const Text('© Yanz Dev Team • Not affiliated with Garena', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}