// 📂 lib/models/emotion_result.dart
class EmotionResult {
  final Map<String, double> probabilities;
  final String feedback;

  EmotionResult({
    required this.probabilities,
    required this.feedback,
  });

  /// 로컬 모델에서 나온 예측값
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

  /// Flask API에서 온 결과
  factory EmotionResult.fromApi(Map<String, dynamic> json) {
    final String topEmotion = json['emotion'];
    final double confidence = (json['confidence'] as num).toDouble();

    return EmotionResult(
      probabilities: {
        topEmotion: confidence,
      },
      feedback: '',
    );
  }

  /// ✅ 추가: 가장 높은 감정 반환
  String get topEmotion {
    if (probabilities.isEmpty) return 'Unknown';
    return probabilities.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// ✅ 추가: topEmotion의 확신도 반환
  double get confidence {
    return probabilities[topEmotion] ?? 0.0;
  }
}