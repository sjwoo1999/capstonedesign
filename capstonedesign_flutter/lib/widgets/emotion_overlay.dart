// 📂 lib/widgets/emotion_overlay.dart
import 'package:flutter/material.dart';

class EmotionOverlay extends StatelessWidget {
  final String emotion;

  const EmotionOverlay({super.key, required this.emotion});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '감정: $emotion',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
