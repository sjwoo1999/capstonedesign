import 'dart:math';

class EmotionDataPoint {
  final DateTime timestamp;
  final double valence; // -1 to 1 (negative to positive)
  final double arousal; // -1 to 1 (calm to excited)
  final double dominance; // -1 to 1 (submissive to dominant)

  EmotionDataPoint({
    required this.timestamp,
    required this.valence,
    required this.arousal,
    required this.dominance,
  });

  // 실제 분석 API가 구현되기 전까지 사용할 임시 목업 데이터 생성 팩토리
  factory EmotionDataPoint.mock() {
    final random = Random();
    return EmotionDataPoint(
      timestamp: DateTime.now(),
      // -1.0 ~ 1.0 범위의 랜덤 값 생성
      valence: random.nextDouble() * 2 - 1,
      arousal: random.nextDouble() * 2 - 1,
      dominance: random.nextDouble() * 2 - 1,
    );
  }

  // 로그 출력 및 서버 전송을 위해 Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'vad': {
        'valence': double.parse(valence.toStringAsFixed(4)),
        'arousal': double.parse(arousal.toStringAsFixed(4)),
        'dominance': double.parse(dominance.toStringAsFixed(4)),
      },
    };
  }
} 