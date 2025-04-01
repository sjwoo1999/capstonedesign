import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emotion_result.dart';
import '../providers/emotion_provider.dart';
import '../widgets/emotion_feedback_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmotionProvider>(context);
    final result = provider.result;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No result available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Emotion Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EmotionFeedbackCard(result: result as EmotionResult),
      ),
    );
  }
}
