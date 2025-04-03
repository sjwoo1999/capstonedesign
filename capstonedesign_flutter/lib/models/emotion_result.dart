class EmotionResult {
  final Map<String, double> probabilities;
  final String feedback;
  final String? errorMessage;

  EmotionResult({
    required this.probabilities,
    required this.feedback,
    this.errorMessage,
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

  factory EmotionResult.fromApi(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return EmotionResult(
        probabilities: {},
        feedback: '',
        errorMessage: json['error'],
      );
    }

    // ✅ 전체 확률 맵 사용
    final Map<String, dynamic> rawProbs = json['probabilities'] ?? {};
    final probabilities = rawProbs.map(
      (k, v) => MapEntry(k.toLowerCase(), (v as num).toDouble()),
    );

    return EmotionResult(
      probabilities: probabilities,
      feedback: '',
    );
  }

  String get topEmotion {
    if (probabilities.isEmpty) return 'Unknown';
    return probabilities.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  double get confidence {
    return probabilities[topEmotion] ?? 0.0;
  }

  bool get isError => errorMessage != null;
}
