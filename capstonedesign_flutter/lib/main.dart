import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/root_screen.dart';
import 'providers/emotion_provider.dart';
import 'providers/vad_provider.dart';
import 'providers/cbt_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/emotion_api_services.dart';
import 'theme/bemore_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Mac의 실제 IP로 고정
  const String serverUrl = 'http://192.168.219.108:5001';
  EmotionAPIService.setBaseUrl(serverUrl);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        ChangeNotifierProvider(create: (_) => VADProvider()),
        ChangeNotifierProvider(create: (_) => CBTProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
