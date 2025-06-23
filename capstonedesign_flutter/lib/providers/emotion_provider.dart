// lib/providers/emotion_provider.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider with ChangeNotifier {
  EmotionResult? result;
  String? errorMessage;
  bool isAnalyzing = false;
  bool _onboardingCompleted = false;

  // 🆕 세션 중 수집된 결과들
  List<EmotionResult> sessionResults = [];

  // 🆕 분석 세션 활성화 여부
  bool isSessionActive = false;

  // 🆕 전체 앱 실행 중 누적 기록 (메모리 기반)
  List<EmotionResult> historyList = [];

  // 온보딩 완료 상태
  bool get onboardingCompleted => _onboardingCompleted;

  void setOnboardingCompleted(bool completed) {
    _onboardingCompleted = completed;
    notifyListeners();
  }

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

  // 🆕 세션 종료 → 평균 결과 반환
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

    final sessionResult = EmotionResult(probabilities: avg, feedback: '');

    // ✅ 세션이 끝날 때 평균 결과를 historyList에 저장
    saveSessionResult(sessionResult);

    return sessionResult;
  }

  // 🆕 세션 결과 저장 (메모리 누적)
  void saveSessionResult(EmotionResult result) {
    historyList.add(result);
    notifyListeners();
  }
}
