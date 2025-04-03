// 📂 lib/widgets/emotion_chart.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionChart extends StatelessWidget {
  final EmotionResult? result;

  const EmotionChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null || result!.probabilities.isEmpty) {
      return const Text('No emotion data available.',
          style: TextStyle(color: Colors.grey));
    }

    final Map<String, double> allEmotions = {
      'Happy': result!.probabilities['happy'] ?? 0.0,
      'Sad': result!.probabilities['sad'] ?? 0.0,
      'Angry': result!.probabilities['angry'] ?? 0.0,
      'Surprised': result!.probabilities['surprised'] ?? 0.0,
      'Disgust': result!.probabilities['disgust'] ?? 0.0,
      'Fear': result!.probabilities['fear'] ?? 0.0,
      'Neutral': result!.probabilities['neutral'] ?? 0.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allEmotions.entries.map((entry) {
        final emotion = entry.key;
        final value = entry.value.clamp(0.0, 1.0); // ensure [0.0, 1.0]

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                  width: 80,
                  child: Text(emotion,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
              Expanded(
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                ),
              ),
              const SizedBox(width: 12),
              Text('${(value * 100).toStringAsFixed(1)}%'),
            ],
          ),
        );
      }).toList(),
    );
  }
}
