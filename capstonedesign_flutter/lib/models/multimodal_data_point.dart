import 'dart:math';

/// 각 모달리티별 분석 결과를 담는 클래스
class ModalityData {
  final double? valence;
  final double? arousal;
  final double? dominance;
  final String? emotion;
  final double? confidence;
  final String? rawData; // 원본 데이터 (base64 이미지, 오디오, 텍스트)

  ModalityData({
    this.valence,
    this.arousal,
    this.dominance,
    this.emotion,
    this.confidence,
    this.rawData,
  });

  Map<String, dynamic> toJson() {
    return {
      if (valence != null) 'valence': valence,
      if (arousal != null) 'arousal': arousal,
      if (dominance != null) 'dominance': dominance,
      if (emotion != null) 'emotion': emotion,
      if (confidence != null) 'confidence': confidence,
      if (rawData != null) 'rawData': rawData,
    };
  }

  factory ModalityData.fromJson(Map<String, dynamic> json) {
    return ModalityData(
      valence: json['valence']?.toDouble(),
      arousal: json['arousal']?.toDouble(),
      dominance: json['dominance']?.toDouble(),
      emotion: json['emotion'],
      confidence: json['confidence']?.toDouble(),
      rawData: json['rawData'],
    );
  }
}

/// 통합된 멀티모달 감정 분석 결과
class MultimodalDataPoint {
  final DateTime timestamp;
  
  // 각 모달리티별 데이터
  final ModalityData? visualData;    // 영상 분석 결과
  final ModalityData? audioData;     // 음성 분석 결과  
  final ModalityData? textData;      // 텍스트 분석 결과
  
  // 통합된 최종 결과
  final double finalValence;
  final double finalArousal;
  final double finalDominance;
  final String finalEmotion;
  final double finalConfidence;
  
  // 추가 메타데이터
  final String? sessionId;
  final Map<String, dynamic>? metadata;

  MultimodalDataPoint({
    required this.timestamp,
    this.visualData,
    this.audioData,
    this.textData,
    required this.finalValence,
    required this.finalArousal,
    required this.finalDominance,
    required this.finalEmotion,
    required this.finalConfidence,
    this.sessionId,
    this.metadata,
  });

  /// 가중 평균을 사용한 통합 VAD 계산
  factory MultimodalDataPoint.fromModalities({
    required DateTime timestamp,
    ModalityData? visualData,
    ModalityData? audioData,
    ModalityData? textData,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    // 각 모달리티별 가중치 (조정 가능)
    const double visualWeight = 0.4;  // 영상 40%
    const double audioWeight = 0.35;   // 음성 35%
    const double textWeight = 0.25;    // 텍스트 25%

    double totalValence = 0.0;
    double totalArousal = 0.0;
    double totalDominance = 0.0;
    double totalConfidence = 0.0;
    double totalWeight = 0.0;

    // 영상 데이터 처리
    if (visualData != null && 
        visualData.valence != null && 
        visualData.arousal != null && 
        visualData.dominance != null) {
      totalValence += visualData.valence! * visualWeight;
      totalArousal += visualData.arousal! * visualWeight;
      totalDominance += visualData.dominance! * visualWeight;
      totalConfidence += (visualData.confidence ?? 0.5) * visualWeight;
      totalWeight += visualWeight;
    }

    // 음성 데이터 처리
    if (audioData != null && 
        audioData.valence != null && 
        audioData.arousal != null && 
        audioData.dominance != null) {
      totalValence += audioData.valence! * audioWeight;
      totalArousal += audioData.arousal! * audioWeight;
      totalDominance += audioData.dominance! * audioWeight;
      totalConfidence += (audioData.confidence ?? 0.5) * audioWeight;
      totalWeight += audioWeight;
    }

    // 텍스트 데이터 처리
    if (textData != null && 
        textData.valence != null && 
        textData.arousal != null && 
        textData.dominance != null) {
      totalValence += textData.valence! * textWeight;
      totalArousal += textData.arousal! * textWeight;
      totalDominance += textData.dominance! * textWeight;
      totalConfidence += (textData.confidence ?? 0.5) * textWeight;
      totalWeight += textWeight;
    }

    // 가중 평균 계산
    final finalValence = totalWeight > 0 ? totalValence / totalWeight : 0.0;
    final finalArousal = totalWeight > 0 ? totalArousal / totalWeight : 0.0;
    final finalDominance = totalWeight > 0 ? totalDominance / totalWeight : 0.0;
    final finalConfidence = totalWeight > 0 ? totalConfidence / totalWeight : 0.0;

    // 최종 감정 결정 (가장 높은 신뢰도를 가진 모달리티의 감정 사용)
    String finalEmotion = 'neutral';
    double maxConfidence = 0.0;

    if (visualData?.confidence != null && visualData!.confidence! > maxConfidence) {
      finalEmotion = visualData.emotion ?? 'neutral';
      maxConfidence = visualData.confidence!;
    }
    if (audioData?.confidence != null && audioData!.confidence! > maxConfidence) {
      finalEmotion = audioData.emotion ?? 'neutral';
      maxConfidence = audioData.confidence!;
    }
    if (textData?.confidence != null && textData!.confidence! > maxConfidence) {
      finalEmotion = textData.emotion ?? 'neutral';
      maxConfidence = textData.confidence!;
    }

    return MultimodalDataPoint(
      timestamp: timestamp,
      visualData: visualData,
      audioData: audioData,
      textData: textData,
      finalValence: finalValence,
      finalArousal: finalArousal,
      finalDominance: finalDominance,
      finalEmotion: finalEmotion,
      finalConfidence: finalConfidence,
      sessionId: sessionId,
      metadata: metadata,
    );
  }

  /// Mock 데이터 생성 (테스트용)
  factory MultimodalDataPoint.mock() {
    final random = Random();
    final timestamp = DateTime.now();
    
    // Mock 모달리티 데이터 생성
    final visualData = ModalityData(
      valence: random.nextDouble() * 2 - 1,
      arousal: random.nextDouble() * 2 - 1,
      dominance: random.nextDouble() * 2 - 1,
      emotion: ['happy', 'sad', 'angry', 'neutral'][random.nextInt(4)],
      confidence: random.nextDouble() * 0.5 + 0.5, // 0.5 ~ 1.0
    );

    final audioData = ModalityData(
      valence: random.nextDouble() * 2 - 1,
      arousal: random.nextDouble() * 2 - 1,
      dominance: random.nextDouble() * 2 - 1,
      emotion: ['happy', 'sad', 'angry', 'neutral'][random.nextInt(4)],
      confidence: random.nextDouble() * 0.5 + 0.5,
    );

    final textData = ModalityData(
      valence: random.nextDouble() * 2 - 1,
      arousal: random.nextDouble() * 2 - 1,
      dominance: random.nextDouble() * 2 - 1,
      emotion: ['happy', 'sad', 'angry', 'neutral'][random.nextInt(4)],
      confidence: random.nextDouble() * 0.5 + 0.5,
    );

    return MultimodalDataPoint.fromModalities(
      timestamp: timestamp,
      visualData: visualData,
      audioData: audioData,
      textData: textData,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'visualData': visualData?.toJson(),
      'audioData': audioData?.toJson(),
      'textData': textData?.toJson(),
      'finalVad': {
        'valence': double.parse(finalValence.toStringAsFixed(4)),
        'arousal': double.parse(finalArousal.toStringAsFixed(4)),
        'dominance': double.parse(finalDominance.toStringAsFixed(4)),
      },
      'finalEmotion': finalEmotion,
      'finalConfidence': double.parse(finalConfidence.toStringAsFixed(4)),
      if (sessionId != null) 'sessionId': sessionId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// JSON 역직렬화
  factory MultimodalDataPoint.fromJson(Map<String, dynamic> json) {
    return MultimodalDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      visualData: json['visualData'] != null 
          ? ModalityData.fromJson(json['visualData']) 
          : null,
      audioData: json['audioData'] != null 
          ? ModalityData.fromJson(json['audioData']) 
          : null,
      textData: json['textData'] != null 
          ? ModalityData.fromJson(json['textData']) 
          : null,
      finalValence: json['finalVad']['valence'].toDouble(),
      finalArousal: json['finalVad']['arousal'].toDouble(),
      finalDominance: json['finalVad']['dominance'].toDouble(),
      finalEmotion: json['finalEmotion'],
      finalConfidence: json['finalConfidence'].toDouble(),
      sessionId: json['sessionId'],
      metadata: json['metadata'],
    );
  }

  /// 사용 가능한 모달리티 개수 반환
  int get availableModalities {
    int count = 0;
    if (visualData != null) count++;
    if (audioData != null) count++;
    if (textData != null) count++;
    return count;
  }

  /// 특정 모달리티가 사용 가능한지 확인
  bool hasModality(String modality) {
    switch (modality.toLowerCase()) {
      case 'visual':
        return visualData != null;
      case 'audio':
        return audioData != null;
      case 'text':
        return textData != null;
      default:
        return false;
    }
  }

  @override
  String toString() {
    return 'MultimodalDataPoint(timestamp: $timestamp, modalities: $availableModalities, finalEmotion: $finalEmotion, confidence: ${finalConfidence.toStringAsFixed(2)})';
  }
} 