// lib/components/emotion_feedback_card.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';
import 'emotion_chart.dart';

class EmotionFeedbackCard extends StatelessWidget {
  final EmotionResult result;

  const EmotionFeedbackCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final top = result.topEmotion;
    final feedback = emotionNicknameMap[top] ?? '';
    final label = emotionLabelMap[top] ?? top;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              feedback,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
