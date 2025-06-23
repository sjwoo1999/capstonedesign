import 'package:flutter/foundation.dart';
import '../models/cbt_feedback.dart';
import '../models/vad_emotion.dart';

class CBTProvider with ChangeNotifier {
  CBTFeedback? _currentFeedback;
  List<CBTFeedback> _feedbackHistory = [];
  bool _isGeneratingFeedback = false;

  // Getters
  CBTFeedback? get currentFeedback => _currentFeedback;
  List<CBTFeedback> get feedbackHistory => _feedbackHistory;
  bool get isGeneratingFeedback => _isGeneratingFeedback;

  // 현재 피드백 설정
  void setCurrentFeedback(CBTFeedback feedback) {
    _currentFeedback = feedback;
    _feedbackHistory.add(feedback);
    notifyListeners();
  }

  // 피드백 생성 상태 설정
  void setGeneratingFeedback(bool generating) {
    _isGeneratingFeedback = generating;
    notifyListeners();
  }

  // 감정에 따른 CBT 피드백 생성
  CBTFeedback generateFeedbackFromEmotion(VADEmotion emotion) {
    setGeneratingFeedback(true);
    
    // 감정 카테고리에 따른 피드백 생성
    CBTFeedback feedback = CBTFeedback.fromEmotion(emotion.emotionCategory);
    
    // VAD 값에 따른 추가 맞춤 피드백
    feedback = _customizeFeedbackByVAD(feedback, emotion);
    
    setCurrentFeedback(feedback);
    setGeneratingFeedback(false);
    
    return feedback;
  }

  // VAD 값에 따른 피드백 맞춤화
  CBTFeedback _customizeFeedbackByVAD(CBTFeedback feedback, VADEmotion emotion) {
    String customizedChallenge = feedback.challenge;
    String customizedReframe = feedback.reframe;
    String customizedActionPlan = feedback.actionPlan;

    // Valence (긍정성) 기반 맞춤화
    if (emotion.valence < 0.3) {
      customizedChallenge += ' 특히 현재 상황에서 긍정적인 면을 찾아보는 것이 도움이 될 수 있습니다.';
      customizedReframe += ' 어려운 시기일수록 작은 성취를 인정하는 것이 중요합니다.';
    } else if (emotion.valence > 0.7) {
      customizedChallenge += ' 긍정적인 감정을 유지하면서도 현실적 시각을 잃지 않도록 주의하세요.';
      customizedReframe += ' 이 순간의 기쁨을 다른 사람과 공유하면 더욱 의미있어집니다.';
    }

    // Arousal (활성화) 기반 맞춤화
    if (emotion.arousal > 0.7) {
      customizedActionPlan += ' 호흡 운동이나 명상을 통해 신체적 긴장을 풀어보세요.';
    } else if (emotion.arousal < 0.3) {
      customizedActionPlan += ' 가벼운 운동이나 산책을 통해 활력을 되찾아보세요.';
    }

    // Dominance (지배성) 기반 맞춤화
    if (emotion.dominance < 0.3) {
      customizedChallenge += ' 상황을 통제할 수 있다는 믿음을 가져보세요.';
      customizedActionPlan += ' 작은 결정부터 시작하여 자신감을 키워보세요.';
    } else if (emotion.dominance > 0.7) {
      customizedChallenge += ' 자신감을 유지하면서도 다른 사람의 의견을 경청해보세요.';
      customizedActionPlan += ' 이 자신감을 활용해 도전적인 목표에 도전해보세요.';
    }

    return CBTFeedback(
      id: feedback.id,
      emotionCategory: feedback.emotionCategory,
      cognitiveDistortion: feedback.cognitiveDistortion,
      challenge: customizedChallenge,
      reframe: customizedReframe,
      actionPlan: customizedActionPlan,
      techniques: feedback.techniques,
      createdAt: feedback.createdAt,
    );
  }

  // 피드백 히스토리에서 특정 감정의 피드백 찾기
  CBTFeedback? getFeedbackByEmotion(String emotionCategory) {
    try {
      return _feedbackHistory
          .where((feedback) => feedback.emotionCategory == emotionCategory)
          .last;
    } catch (e) {
      return null;
    }
  }

  // 최근 피드백 가져오기
  List<CBTFeedback> getRecentFeedbacks(int count) {
    _feedbackHistory.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _feedbackHistory.take(count).toList();
  }

  // 피드백 통계
  Map<String, dynamic> getFeedbackStats() {
    if (_feedbackHistory.isEmpty) {
      return {
        'totalFeedbacks': 0,
        'mostCommonEmotion': '없음',
        'averageTechniques': 0,
      };
    }

    // 가장 많이 나타난 감정
    Map<String, int> emotionCounts = {};
    for (var feedback in _feedbackHistory) {
      String emotion = feedback.emotionCategory;
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
    }

    String mostCommonEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // 평균 기법 수
    double avgTechniques = _feedbackHistory
        .map((f) => f.techniques.length)
        .reduce((a, b) => a + b) / _feedbackHistory.length;

    return {
      'totalFeedbacks': _feedbackHistory.length,
      'mostCommonEmotion': mostCommonEmotion,
      'averageTechniques': avgTechniques,
    };
  }

  // 피드백 히스토리 초기화
  void clearFeedbackHistory() {
    _feedbackHistory.clear();
    _currentFeedback = null;
    notifyListeners();
  }

  // 특정 피드백 삭제
  void removeFeedback(String feedbackId) {
    _feedbackHistory.removeWhere((feedback) => feedback.id == feedbackId);
    if (_currentFeedback?.id == feedbackId) {
      _currentFeedback = null;
    }
    notifyListeners();
  }
} 