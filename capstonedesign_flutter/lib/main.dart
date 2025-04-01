// 📂 lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:capstonedesign_flutter/providers/emotion_provider.dart';
import 'package:capstonedesign_flutter/services/tflite_service.dart';
import 'package:capstonedesign_flutter/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tfliteService = TFLiteService();
  await tfliteService.loadModel();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmotionProvider()),
        Provider<TFLiteService>.value(value: tfliteService),
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
      title: 'CapstoneDesign',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
