import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/device_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await DeviceService.init();
  runApp(const YanzCheatApp());
}

class YanzCheatApp extends StatelessWidget {
  const YanzCheatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FF Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF07060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC9A227),
          secondary: Color(0xFFB3121F),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}