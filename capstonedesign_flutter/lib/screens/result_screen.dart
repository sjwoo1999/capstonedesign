import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmotionProvider>(context);
    final result = provider.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Result')),
        body: Center(child: Text('No result available')),
      );
    }

    final maxEmotion = {
      'Happiness': result.happiness,
      'Sadness': result.sadness,
      'Anger': result.anger,
      'Surprise': result.surprise,
      'Disgust': result.disgust,
      'Fear': result.fear,
      'Neutral': result.neutral,
    }.entries.reduce((a, b) => a.value > b.value ? a : b);

    return Scaffold(
      appBar: AppBar(title: Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Main Emotion: ${maxEmotion.key} (${(maxEmotion.value * 100).toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Happiness: ${(result.happiness * 100).toStringAsFixed(1)}%'),
            Text('Sadness: ${(result.sadness * 100).toStringAsFixed(1)}%'),
            Text('Anger: ${(result.anger * 100).toStringAsFixed(1)}%'),
            Text('Surprise: ${(result.surprise * 100).toStringAsFixed(1)}%'),
            Text('Disgust: ${(result.disgust * 100).toStringAsFixed(1)}%'),
            Text('Fear: ${(result.fear * 100).toStringAsFixed(1)}%'),
            Text('Neutral: ${(result.neutral * 100).toStringAsFixed(1)}%'),
            SizedBox(height: 20),
            Text('Feedback:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(result.feedback),
          ],
        ),
      ),
    );
  }
}
