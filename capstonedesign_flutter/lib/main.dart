// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstonedesign_flutter/providers/emotion_provider.dart';
import 'package:capstonedesign_flutter/services/tflite_service.dart';
import 'package:capstonedesign_flutter/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tfliteService = TFLiteService();
  try {
    await tfliteService.loadModel();
  } catch (e) {
    print('Failed to load TFLite model: $e');
    // 에러 처리 (예: 기본 UI 표시)
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        Provider(create: (_) => tfliteService),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapstoneDesign',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
