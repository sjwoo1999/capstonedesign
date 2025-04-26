import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/emotion_provider.dart';
import 'screens/home_screen.dart';
import 'services/emotion_api_services.dart';
import 'services/server_discovery_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ .env 로드
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded: ${dotenv.env['EMOTION_API_URL']}");
  } catch (e) {
    print("❌ .env 로드 실패: $e");
  }

  // ✅ 서버 탐색 → 성공 시 API URL 설정
  try {
    final serverUrl = await ServerDiscoveryService.findServer();

    if (serverUrl != null) {
      EmotionAPIService.setBaseUrl(serverUrl);
    } else {
      print('❌ 서버를 찾을 수 없습니다.');
      EmotionAPIService.setBaseUrl(dotenv.env['EMOTION_API_URL'] ?? 'http://127.0.0.1:5001');
    }
  } catch (e) {
    print('⚠️ 서버 탐색 중 예외 발생: $e');
    EmotionAPIService.setBaseUrl(dotenv.env['EMOTION_API_URL'] ?? 'http://127.0.0.1:5001');
  }

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
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}