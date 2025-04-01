// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../services/tflite_service.dart';
import 'result_screen.dart';

class LoadingScreen extends StatefulWidget {
  final String base64Image;
  const LoadingScreen({super.key, required this.base64Image});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _analyzeEmotion();
  }

  Future<void> _analyzeEmotion() async {
    final provider = Provider.of<EmotionProvider>(context, listen: false);
    final tflite = Provider.of<TFLiteService>(context, listen: false);

    await provider.analyze(image: widget.base64Image, tflite: tflite);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ResultScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("감정을 분석 중입니다...", style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
