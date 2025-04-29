// lib/screens/session/session_result_screen.dart
import 'package:flutter/material.dart';
import '../../models/emotion_result.dart';
import '../../constants/emotion_constants.dart';
import '../root_screen.dart'; // 홈으로 이동하려면 필요

class SessionResultScreen extends StatelessWidget {
  final EmotionResult result;

  const SessionResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final topEmotion = result.topEmotion;
    final emoji = emotionLabelMap[topEmotion] ?? '';
    final nickname = emotionNicknameMap[topEmotion] ?? topEmotion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('분석 결과'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              nickname,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...result.probabilities.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      emotionNicknameMap[entry.key] ?? entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Text(
                    '${(entry.value * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 32),
            Text(
              _generateComment(topEmotion),
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const RootScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 50),
              ),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateComment(String emotion) {
    switch (emotion) {
      case 'happy':
        return '오늘 기분이 좋아 보여요! 🌟\n이 기분을 이어가세요.';
      case 'sad':
        return '조금 우울한 기분이 느껴져요. 🥲\n가벼운 산책을 추천드려요.';
      case 'angry':
        return '화가 나셨나요? 😡\n깊게 숨쉬며 천천히 마음을 가라앉혀보세요.';
      case 'fear':
        return '불안한 기운이 감지됐어요. 😥\n편안한 음악을 들어보세요.';
      case 'disgust':
        return '불쾌한 감정이 느껴졌어요. 😖\n좋아하는 활동으로 기분 전환을 해보세요.';
      case 'surprised':
        return '놀라운 일이 있었나요? 😲\n차분히 상황을 정리해보세요.';
      default:
        return '평온한 상태네요. 🙂\n오늘도 수고 많으셨어요.';
    }
  }
}
