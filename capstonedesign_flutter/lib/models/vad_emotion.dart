class VADEmotion {
  final double valence;    // 감정의 긍정성 (0.0 ~ 1.0)
  final double arousal;    // 감정의 활성화 정도 (0.0 ~ 1.0)
  final double dominance;  // 감정의 지배성 (0.0 ~ 1.0)
  final DateTime timestamp;
  final String source;     // 'facial', 'voice', 'text', 'combined'

  VADEmotion({
    required this.valence,
    required this.arousal,
    required this.dominance,
    required this.timestamp,
    required this.source,
  });

  // VAD 값을 감정 카테고리로 변환
  String get emotionCategory {
    if (valence > 0.6 && arousal > 0.6) return '기쁨';
    if (valence > 0.6 && arousal < 0.4) return '평온';
    if (valence < 0.4 && arousal > 0.6) return '분노';
    if (valence < 0.4 && arousal < 0.4) return '슬픔';
    if (valence > 0.6 && arousal > 0.4 && arousal < 0.6) return '희망';
    if (valence < 0.4 && arousal > 0.4 && arousal < 0.6) return '불안';
    return '중립';
  }

  // VAD 값을 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'valence': valence,
      'arousal': arousal,
      'dominance': dominance,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  // JSON에서 VAD 객체 생성
  factory VADEmotion.fromJson(Map<String, dynamic> json) {
    return VADEmotion(
      valence: json['valence'].toDouble(),
      arousal: json['arousal'].toDouble(),
      dominance: json['dominance'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      source: json['source'],
    );
  }

  // VAD 값들의 평균 계산
  static VADEmotion average(List<VADEmotion> emotions, String source) {
    if (emotions.isEmpty) {
      return VADEmotion(
        valence: 0.5,
        arousal: 0.5,
        dominance: 0.5,
        timestamp: DateTime.now(),
        source: source,
      );
    }

    double avgValence = emotions.map((e) => e.valence).reduce((a, b) => a + b) / emotions.length;
    double avgArousal = emotions.map((e) => e.arousal).reduce((a, b) => a + b) / emotions.length;
    double avgDominance = emotions.map((e) => e.dominance).reduce((a, b) => a + b) / emotions.length;

    return VADEmotion(
      valence: avgValence,
      arousal: avgArousal,
      dominance: avgDominance,
      timestamp: DateTime.now(),
      source: source,
    );
  }
} 