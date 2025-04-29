import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../constants/emotion_constants.dart';

class ReportHistoryScreen extends StatelessWidget {
  const ReportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyList = context.watch<EmotionProvider>().historyList.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('과거 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: historyList.isEmpty
            ? const Center(
                child: Text(
                  '아직 기록된 분석이 없습니다.\n지금 바로 감정 분석을 시작해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final result = historyList[index];
                  final topEmotion = result.topEmotion;
                  final emoji = emotionLabelMap[topEmotion] ?? '';
                  final nickname = emotionNicknameMap[topEmotion] ?? topEmotion;
                  final confidence = (result.probabilities[topEmotion]! * 100).toStringAsFixed(1);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    child: ListTile(
                      leading: Text(
                        emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      title: Text(
                        nickname,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$confidence% 확신'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
