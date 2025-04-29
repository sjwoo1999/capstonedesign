// lib/providers/emotion_provider.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider with ChangeNotifier {
  EmotionResult? result;
  String? errorMessage;
  bool isAnalyzing = false;

  // 🆕 추가
  List<EmotionResult> sessionResults = [];
  bool isSessionActive = false;

  void startCameraAnalysis() {
    isAnalyzing = true;
    notifyListeners();
  }

  void endCameraAnalysis() {
    isAnalyzing = false;
    notifyListeners();
  }

  void setResultFromApi(Map<String, dynamic> data) {
    result = EmotionResult.fromApi(data);
    if (isSessionActive && result != null) {
      sessionResults.add(result!);
    }
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // 🆕 세션 시작
  void startSession() {
    sessionResults.clear();
    isSessionActive = true;
    notifyListeners();
  }

  // 🆕 세션 종료
  EmotionResult endSession() {
    isSessionActive = false;
    if (sessionResults.isEmpty) {
      // 아무 데이터 없으면 neutral 리턴
      return EmotionResult(
        probabilities: {
          'happy': 0,
          'sad': 0,
          'angry': 0,
          'surprised': 0,
          'disgust': 0,
          'fear': 0,
          'neutral': 1,
        },
        feedback: '',
      );
    }
    // 평균 계산
    final Map<String, double> sum = {
      'happy': 0,
      'sad': 0,
      'angry': 0,
      'surprised': 0,
      'disgust': 0,
      'fear': 0,
      'neutral': 0,
    };
    for (var r in sessionResults) {
      r.probabilities.forEach((key, value) {
        sum[key] = (sum[key] ?? 0) + value;
      });
    }
    final avg = sum.map((key, value) => MapEntry(key, value / sessionResults.length));
    return EmotionResult(probabilities: avg, feedback: '');
  }
}
