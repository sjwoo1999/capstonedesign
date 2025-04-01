// 📂 lib/models/emotion_result.dart
class EmotionResult {
  final Map<String, double> probabilities;
  final String feedback;

  EmotionResult({
    required this.probabilities,
    required this.feedback,
  });

  factory EmotionResult.fromLocal(List<double> preds) {
    return EmotionResult(
      probabilities: {
        'happy': preds[0],
        'sad': preds[1],
        'angry': preds[2],
        'surprised': preds[3],
        'disgust': preds[4],
        'fear': preds[5],
        'neutral': preds[6],
      },
      feedback: '',
    );
  }
}
