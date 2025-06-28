// lib/models/emotion_result.dart
import 'emotion_data_point.dart';
import 'multimodal_data_point.dart';

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

  factory EmotionResult.fromJson(Map<String, dynamic> json) {
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

  /// MultimodalDataPoint로부터 EmotionResult 생성
  factory EmotionResult.fromMultimodalData(MultimodalDataPoint multimodalData) {
    // 감정을 확률로 변환 (가장 높은 신뢰도를 가진 모달리티의 감정을 우선)
    final emotions = ['happy', 'sad', 'angry', 'surprised', 'disgust', 'fear', 'neutral'];
    final probabilities = <String, double>{};
    
    // 모든 감정에 기본값 0 설정
    for (final emotion in emotions) {
      probabilities[emotion] = 0.0;
    }

    // 최종 감정에 높은 확률 부여
    final finalEmotion = multimodalData.finalEmotion.toLowerCase();
    if (probabilities.containsKey(finalEmotion)) {
      probabilities[finalEmotion] = multimodalData.finalConfidence;
    } else {
      probabilities['neutral'] = multimodalData.finalConfidence;
    }

    // 나머지 감정들에 낮은 확률 분배
    final remainingProb = (1.0 - multimodalData.finalConfidence) / (emotions.length - 1);
    for (final emotion in emotions) {
      if (emotion != finalEmotion) {
        probabilities[emotion] = remainingProb;
      }
    }

    return EmotionResult(
      probabilities: probabilities,
      feedback: _generateFeedbackFromMultimodal(multimodalData),
    );
  }

  /// EmotionDataPoint로부터 EmotionResult 생성
  factory EmotionResult.fromEmotionDataPoint(EmotionDataPoint dataPoint) {
    final emotions = ['happy', 'sad', 'angry', 'surprised', 'disgust', 'fear', 'neutral'];
    final probabilities = <String, double>{};
    
    // 모든 감정에 기본값 0 설정
    for (final emotion in emotions) {
      probabilities[emotion] = 0.0;
    }

    // 감정에 확률 부여
    final emotion = dataPoint.emotion?.toLowerCase() ?? 'neutral';
    final confidence = dataPoint.confidence ?? 0.5;
    
    if (probabilities.containsKey(emotion)) {
      probabilities[emotion] = confidence;
    } else {
      probabilities['neutral'] = confidence;
    }

    // 나머지 감정들에 낮은 확률 분배
    final remainingProb = (1.0 - confidence) / (emotions.length - 1);
    for (final emotionKey in emotions) {
      if (emotionKey != emotion) {
        probabilities[emotionKey] = remainingProb;
      }
    }

    return EmotionResult(
      probabilities: probabilities,
      feedback: _generateFeedbackFromDataPoint(dataPoint),
    );
  }

  /// MultimodalDataPoint로부터 피드백 생성
  static String _generateFeedbackFromMultimodal(MultimodalDataPoint multimodalData) {
    final modalities = multimodalData.availableModalities;
    final emotion = multimodalData.finalEmotion;
    final confidence = multimodalData.finalConfidence;

    String feedback = '';

    // 모달리티 정보
    if (modalities >= 3) {
      feedback += '영상, 음성, 텍스트를 모두 분석했습니다. ';
    } else if (modalities == 2) {
      feedback += '두 가지 모달리티를 분석했습니다. ';
    } else {
      feedback += '하나의 모달리티를 분석했습니다. ';
    }

    // 감정별 피드백
    switch (emotion.toLowerCase()) {
      case 'happy':
        feedback += '기분이 좋아 보입니다!';
        break;
      case 'sad':
        feedback += '슬픈 감정이 느껴집니다.';
        break;
      case 'angry':
        feedback += '화가 난 상태로 보입니다.';
        break;
      case 'surprised':
        feedback += '놀란 상태입니다.';
        break;
      case 'disgust':
        feedback += '싫어하는 감정이 느껴집니다.';
        break;
      case 'fear':
        feedback += '두려운 감정이 느껴집니다.';
        break;
      default:
        feedback += '중립적인 감정 상태입니다.';
    }

    // 신뢰도 정보
    if (confidence >= 0.8) {
      feedback += ' (높은 신뢰도)';
    } else if (confidence >= 0.6) {
      feedback += ' (보통 신뢰도)';
    } else {
      feedback += ' (낮은 신뢰도)';
    }

    return feedback;
  }

  /// EmotionDataPoint로부터 피드백 생성
  static String _generateFeedbackFromDataPoint(EmotionDataPoint dataPoint) {
    final emotion = dataPoint.emotion ?? 'neutral';
    final confidence = dataPoint.confidence ?? 0.5;
    final hasMultimodal = dataPoint.hasMultimodalData;

    String feedback = '';

    // 멀티모달 정보
    if (hasMultimodal) {
      final modalities = dataPoint.availableModalities;
      if (modalities >= 3) {
        feedback += '멀티모달 분석: 영상, 음성, 텍스트 모두 사용. ';
      } else if (modalities == 2) {
        feedback += '멀티모달 분석: 두 가지 모달리티 사용. ';
      } else {
        feedback += '멀티모달 분석: 하나의 모달리티 사용. ';
      }
    }

    // 감정별 피드백
    switch (emotion.toLowerCase()) {
      case 'happy':
        feedback += '기분이 좋아 보입니다!';
        break;
      case 'sad':
        feedback += '슬픈 감정이 느껴집니다.';
        break;
      case 'angry':
        feedback += '화가 난 상태로 보입니다.';
        break;
      case 'surprised':
        feedback += '놀란 상태입니다.';
        break;
      case 'disgust':
        feedback += '싫어하는 감정이 느껴집니다.';
        break;
      case 'fear':
        feedback += '두려운 감정이 느껴집니다.';
        break;
      default:
        feedback += '중립적인 감정 상태입니다.';
    }

    // 신뢰도 정보
    if (confidence >= 0.8) {
      feedback += ' (높은 신뢰도)';
    } else if (confidence >= 0.6) {
      feedback += ' (보통 신뢰도)';
    } else {
      feedback += ' (낮은 신뢰도)';
    }

    return feedback;
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
