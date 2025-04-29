// lib/screens/report/report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../constants/emotion_constants.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyList = context.watch<EmotionProvider>().historyList.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('과거 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: historyList.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                itemCount: historyList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final result = historyList[index];
                  final topEmotion = result.topEmotion;
                  final emoji = emotionLabelMap[topEmotion] ?? '';
                  final nickname = emotionNicknameMap[topEmotion] ?? topEmotion;
                  final confidence = (result.probabilities[topEmotion]! * 100).toStringAsFixed(1);

                  return _buildHistoryCard(emoji, nickname, confidence);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '아직 기록된 분석이 없습니다.\n\n지금 바로 감정 분석을 시작해보세요!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(String emoji, String nickname, String confidence) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(
          emoji,
          style: const TextStyle(fontSize: 36),
        ),
        title: Text(
          nickname,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '확신도: $confidence%',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}
