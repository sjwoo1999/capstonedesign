// lib/models/emotion_result.dart
class EmotionResult {
  final double happiness;
  final double sadness;
  final double anger;
  final double surprise;
  final double disgust;
  final double fear;
  final double neutral;
  final String feedback;

  EmotionResult({
    required this.happiness,
    required this.sadness,
    required this.anger,
    required this.surprise,
    required this.disgust,
    required this.fear,
    required this.neutral,
    required this.feedback,
  });

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      happiness: json['emotion']['happiness'] ?? 0.0,
      sadness: json['emotion']['sadness'] ?? 0.0,
      anger: json['emotion']['anger'] ?? 0.0,
      surprise: json['emotion']['surprise'] ?? 0.0,
      disgust: json['emotion']['disgust'] ?? 0.0,
      fear: json['emotion']['fear'] ?? 0.0,
      neutral: json['emotion']['neutral'] ?? 0.0,
      feedback: json['feedback'] ?? '',
    );
  }
}
