import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/emotion_provider.dart';
import 'screens/root_screen.dart';
import 'services/emotion_api_services.dart';
import 'services/server_discovery_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  String? serverUrl;

  try {
    serverUrl = await ServerDiscoveryService.findServer();
    if (serverUrl != null) {
      print('✅ 서버 탐색 성공: $serverUrl');
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '마음온도',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'NotoSansKR',
            ),
        fontFamily: 'NotoSansKR',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 1,
        ),
      ),
      home: const RootScreen(),
    );
  }
}
