import 'package:flutter/material.dart';
import '../models/emotion_result.dart';
import '../utils/emotion_color_mapper.dart';
import '../utils/emoji_mapper.dart';

class EmotionFeedbackCard extends StatelessWidget {
  final EmotionResult result;

  const EmotionFeedbackCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    final mainEmotionEntry = result.probabilities.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    final emotion = mainEmotionEntry.key;
    final percentage = (mainEmotionEntry.value * 100).toStringAsFixed(1);
    final color = emotionColorMapper(emotion);
    final emoji = emojiMapper(emotion);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.15),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$emoji  Today's Emotion: ${_capitalize(emotion)}",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('🧠 Analysis Result:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...result.probabilities.entries.map((entry) => Text(
                '${_capitalize(entry.key)}: ${(entry.value * 100).toStringAsFixed(1)}%')),
            const SizedBox(height: 16),
            const Text('📝 Reflection:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              result.feedback.isNotEmpty
                  ? result.feedback
                  : 'No feedback provided.',
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
