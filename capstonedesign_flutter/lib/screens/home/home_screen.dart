// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../record/record_screen.dart'; // 분석 시작 화면 이동용

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToRecord(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final descriptionSection = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.emoji_emotions,
          size: 80,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 24),
        const Text(
          '마음 상태를 한눈에 분석해드립니다.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          '카메라를 바라보며 감정을 기록하고\n분석 결과를 확인하세요.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );

    final buttonSection = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: () => _navigateToRecord(context),
          icon: const Icon(Icons.camera_alt),
          label: const Text('분석 시작하기'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 56),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '🙌 분석 영상은 저장되지 않습니다.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLandscape
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: descriptionSection),
                    const SizedBox(width: 64),
                    Flexible(child: buttonSection),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    descriptionSection,
                    const SizedBox(height: 48),
                    buttonSection,
                  ],
                ),
        ),
      ),
    );
  }
}
