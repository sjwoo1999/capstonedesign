import 'package:flutter/foundation.dart';
import '../models/vad_emotion.dart';

class VADProvider with ChangeNotifier {
  VADEmotion? _currentEmotion;
  List<VADEmotion> _facialEmotions = [];
  List<VADEmotion> _voiceEmotions = [];
  List<VADEmotion> _textEmotions = [];
  VADEmotion? _combinedEmotion;
  bool _isAnalyzing = false;

  // Getters
  VADEmotion? get currentEmotion => _currentEmotion;
  List<VADEmotion> get facialEmotions => _facialEmotions;
  List<VADEmotion> get voiceEmotions => _voiceEmotions;
  List<VADEmotion> get textEmotions => _textEmotions;
  VADEmotion? get combinedEmotion => _combinedEmotion;
  bool get isAnalyzing => _isAnalyzing;

  // 얼굴 표정 감정 추가
  void addFacialEmotion(VADEmotion emotion) {
    _facialEmotions.add(emotion);
    _updateCombinedEmotion();
    notifyListeners();
  }

  // 음성 감정 추가
  void addVoiceEmotion(VADEmotion emotion) {
    _voiceEmotions.add(emotion);
    _updateCombinedEmotion();
    notifyListeners();
  }

  // 텍스트 감정 추가
  void addTextEmotion(VADEmotion emotion) {
    _textEmotions.add(emotion);
    _updateCombinedEmotion();
    notifyListeners();
  }

  // 현재 감정 설정
  void setCurrentEmotion(VADEmotion emotion) {
    _currentEmotion = emotion;
    notifyListeners();
  }

  // 분석 상태 설정
  void setAnalyzing(bool analyzing) {
    _isAnalyzing = analyzing;
    notifyListeners();
  }

  // 통합 감정 계산
  void _updateCombinedEmotion() {
    List<VADEmotion> allEmotions = [];
    allEmotions.addAll(_facialEmotions);
    allEmotions.addAll(_voiceEmotions);
    allEmotions.addAll(_textEmotions);

    if (allEmotions.isNotEmpty) {
      _combinedEmotion = VADEmotion.average(allEmotions, 'combined');
    }
  }

  // 모든 감정 데이터 초기화
  void clearAllEmotions() {
    _facialEmotions.clear();
    _voiceEmotions.clear();
    _textEmotions.clear();
    _combinedEmotion = null;
    _currentEmotion = null;
    notifyListeners();
  }

  // 특정 소스의 감정 데이터만 초기화
  void clearEmotionsBySource(String source) {
    switch (source) {
      case 'facial':
        _facialEmotions.clear();
        break;
      case 'voice':
        _voiceEmotions.clear();
        break;
      case 'text':
        _textEmotions.clear();
        break;
    }
    _updateCombinedEmotion();
    notifyListeners();
  }

  // 감정 변화 추이 계산 (최근 N개)
  List<VADEmotion> getRecentEmotions(int count) {
    List<VADEmotion> allEmotions = [];
    allEmotions.addAll(_facialEmotions);
    allEmotions.addAll(_voiceEmotions);
    allEmotions.addAll(_textEmotions);
    
    allEmotions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEmotions.take(count).toList();
  }

  // 감정 통계 계산
  Map<String, dynamic> getEmotionStats() {
    List<VADEmotion> allEmotions = [];
    allEmotions.addAll(_facialEmotions);
    allEmotions.addAll(_voiceEmotions);
    allEmotions.addAll(_textEmotions);

    if (allEmotions.isEmpty) {
      return {
        'avgValence': 0.5,
        'avgArousal': 0.5,
        'avgDominance': 0.5,
        'dominantEmotion': '중립',
        'emotionCount': 0,
      };
    }

    double avgValence = allEmotions.map((e) => e.valence).reduce((a, b) => a + b) / allEmotions.length;
    double avgArousal = allEmotions.map((e) => e.arousal).reduce((a, b) => a + b) / allEmotions.length;
    double avgDominance = allEmotions.map((e) => e.dominance).reduce((a, b) => a + b) / allEmotions.length;

    // 가장 많이 나타난 감정 카테고리
    Map<String, int> emotionCounts = {};
    for (var emotion in allEmotions) {
      String category = emotion.emotionCategory;
      emotionCounts[category] = (emotionCounts[category] ?? 0) + 1;
    }

    String dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'avgValence': avgValence,
      'avgArousal': avgArousal,
      'avgDominance': avgDominance,
      'dominantEmotion': dominantEmotion,
      'emotionCount': allEmotions.length,
    };
  }
} 