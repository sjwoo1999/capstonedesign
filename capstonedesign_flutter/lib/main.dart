import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/emotion_provider.dart';
import 'providers/vad_provider.dart';
import 'providers/cbt_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/emotion_api_services.dart';
import 'services/server_discovery_service.dart';
import 'theme/bemore_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  String? serverUrl;

  try {
    serverUrl = await ServerDiscoveryService.findServer();
    if (serverUrl != null) {
      print('✅ BeMore 서버 탐색 성공: $serverUrl');
    } else {
      print('🛟 서버 탐색 실패, fallback 사용');
    }
  } catch (e) {
    print('⚠️ 서버 탐색 중 예외 발생: $e');
  }

  EmotionAPIService.setBaseUrl(
    serverUrl ?? dotenv.env['EMOTION_API_URL'] ?? 'http://127.0.0.1:5001',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        ChangeNotifierProvider(create: (_) => VADProvider()),
        ChangeNotifierProvider(create: (_) => CBTProvider()),
      ],
      child: const BeMoreApp(),
    ),
  );
}

class BeMoreApp extends StatelessWidget {
  const BeMoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BeMore',
      theme: BeMoreTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
