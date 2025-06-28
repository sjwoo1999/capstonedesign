import 'dart:math';
import 'multimodal_data_point.dart';

class EmotionDataPoint {
  final DateTime timestamp;
  final double valence; // -1 to 1 (negative to positive)
  final double arousal; // -1 to 1 (calm to excited)
  final double dominance; // -1 to 1 (submissive to dominant)
  final String? text; // 인식된 텍스트 (선택적)
  final String? emotion; // 감정 태그 (선택적)
  final double? confidence; // 신뢰도 (선택적)
  
  // 멀티모달 데이터 지원을 위한 추가 필드
  final MultimodalDataPoint? multimodalData; // 멀티모달 분석 결과

  EmotionDataPoint({
    required this.timestamp,
    required this.valence,
    required this.arousal,
    required this.dominance,
    this.text,
    this.emotion,
    this.confidence,
    this.multimodalData,
  });

  /// MultimodalDataPoint로부터 EmotionDataPoint 생성
  factory EmotionDataPoint.fromMultimodal(MultimodalDataPoint multimodal) {
    return EmotionDataPoint(
      timestamp: multimodal.timestamp,
      valence: multimodal.finalValence,
      arousal: multimodal.finalArousal,
      dominance: multimodal.finalDominance,
      emotion: multimodal.finalEmotion,
      confidence: multimodal.finalConfidence,
      multimodalData: multimodal,
      // 텍스트는 textData에서 추출
      text: multimodal.textData?.rawData,
    );
  }

  /// VAD 데이터로부터 EmotionDataPoint 생성
  factory EmotionDataPoint.fromVad({
    required DateTime timestamp,
    required Map<String, double> vad,
    String? text,
    String? emotion,
    double? confidence,
  }) {
    return EmotionDataPoint(
      timestamp: timestamp,
      valence: vad['valence'] ?? 0.0,
      arousal: vad['arousal'] ?? 0.0,
      dominance: vad['dominance'] ?? 0.0,
      text: text,
      emotion: emotion,
      confidence: confidence,
    );
  }

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

  /// 멀티모달 데이터가 있는지 확인
  bool get hasMultimodalData => multimodalData != null;

  /// 사용 가능한 모달리티 개수 반환
  int get availableModalities => multimodalData?.availableModalities ?? 0;

  /// 특정 모달리티가 사용 가능한지 확인
  bool hasModality(String modality) {
    return multimodalData?.hasModality(modality) ?? false;
  }

  /// 멀티모달 분석 품질 평가
  double get analysisQuality {
    if (multimodalData == null) return confidence ?? 0.5;
    
    double quality = 0.0;
    int modalityCount = 0;

    if (multimodalData!.visualData != null) {
      quality += multimodalData!.visualData!.confidence ?? 0.5;
      modalityCount++;
    }
    if (multimodalData!.audioData != null) {
      quality += multimodalData!.audioData!.confidence ?? 0.5;
      modalityCount++;
    }
    if (multimodalData!.textData != null) {
      quality += multimodalData!.textData!.confidence ?? 0.5;
      modalityCount++;
    }

    // 모달리티 개수에 따른 보너스
    if (modalityCount > 1) {
      quality += (modalityCount - 1) * 0.1;
    }

    return modalityCount > 0 ? quality / modalityCount : 0.0;
  }

  // 로그 출력 및 서버 전송을 위해 Map 형태로 변환 (JSON 직렬화)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'vad': {
        'valence': double.parse(valence.toStringAsFixed(4)),
        'arousal': double.parse(arousal.toStringAsFixed(4)),
        'dominance': double.parse(dominance.toStringAsFixed(4)),
      },
    };
    
    // 선택적 필드들 추가 (null 체크 후)
    if (text != null) json['text'] = text!;
    if (emotion != null) json['emotion'] = emotion!;
    if (confidence != null) json['confidence'] = confidence!;
    
    // 멀티모달 데이터 추가
    if (multimodalData != null) {
      json['multimodal_data'] = multimodalData!.toJson();
    }
    
    return json;
  }

  /// JSON 역직렬화
  factory EmotionDataPoint.fromJson(Map<String, dynamic> json) {
    MultimodalDataPoint? multimodalData;
    if (json.containsKey('multimodal_data')) {
      multimodalData = MultimodalDataPoint.fromJson(json['multimodal_data']);
    }

    return EmotionDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      valence: json['vad']['valence'].toDouble(),
      arousal: json['vad']['arousal'].toDouble(),
      dominance: json['vad']['dominance'].toDouble(),
      text: json['text'],
      emotion: json['emotion'],
      confidence: json['confidence']?.toDouble(),
      multimodalData: multimodalData,
    );
  }

  /// 분석 결과 요약 문자열 생성
  String get analysisSummary {
    if (hasMultimodalData) {
      return '''
멀티모달 감정 분석 결과:
- 사용된 모달리티: $availableModalities개
- 최종 감정: $emotion
- 신뢰도: ${((confidence ?? 0.0) * 100).toStringAsFixed(1)}%
- 분석 품질: ${(analysisQuality * 100).toStringAsFixed(1)}%
- VAD: (${valence.toStringAsFixed(2)}, ${arousal.toStringAsFixed(2)}, ${dominance.toStringAsFixed(2)})
''';
    } else {
      return '''
감정 분석 결과:
- 감정: $emotion
- 신뢰도: ${((confidence ?? 0.0) * 100).toStringAsFixed(1)}%
- VAD: (${valence.toStringAsFixed(2)}, ${arousal.toStringAsFixed(2)}, ${dominance.toStringAsFixed(2)})
''';
    }
  }

  @override
  String toString() {
    if (hasMultimodalData) {
      return 'EmotionDataPoint(timestamp: $timestamp, modalities: $availableModalities, emotion: $emotion, confidence: ${confidence?.toStringAsFixed(2)})';
    } else {
      return 'EmotionDataPoint(timestamp: $timestamp, emotion: $emotion, confidence: ${confidence?.toStringAsFixed(2)})';
    }
  }
} 