// lib/models/emotion_result.dart
class EmotionResult {
  final Map<String, double> probabilities;
  final String feedback;

  EmotionResult({
    required this.probabilities,
    required this.feedback,
  });

  factory EmotionResult.fromApi(Map<String, dynamic> json) {
    return EmotionResult(
      probabilities: Map<String, double>.from(json['probabilities']),
      feedback: json['feedback'] ?? '',
    );
  }

  factory EmotionResult.fromLocal(List<double> data) {
    final emotions = ['happy', 'sad', 'angry', 'surprised', 'disgust', 'fear', 'neutral'];
    final probabilities = Map<String, double>.fromIterables(emotions, data);
    return EmotionResult(
      probabilities: probabilities,
      feedback: '',
    );
  }

  double get confidence {
    if (probabilities.isEmpty) return 0.0;
    return probabilities.values.reduce((a, b) => a > b ? a : b);
  }

  String get topEmotion {
    if (probabilities.isEmpty) return 'neutral';
    return probabilities.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
