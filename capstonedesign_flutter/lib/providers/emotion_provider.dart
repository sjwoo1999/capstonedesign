import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider extends ChangeNotifier {
  /// 🔹 감정 분석 결과 객체
  EmotionResult? _result;
  EmotionResult? get result => _result;

  /// 🔹 감정 분석 실패 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 🔹 텍스트 분석 중 상태
  bool _isAnalyzingText = false;
  bool get isAnalyzingText => _isAnalyzingText;

  /// 🔹 카메라 분석 중 상태 🔥 추가
  bool _isAnalyzingCamera = false;
  bool get isAnalyzingCamera => _isAnalyzingCamera;

  void setResult(EmotionResult result) {
    _result = result;
    _errorMessage = null;
    notifyListeners();
  }

  void setResultFromApi(Map<String, dynamic> json) {
    _result = EmotionResult.fromApi(json);
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _result = null;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// 🧪 텍스트 감정 분석 예시용
  Future<void> analyze({required String text}) async {
    _isAnalyzingText = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));
      setResult(EmotionResult.fromLocal([
        0.3, 0.2, 0.1, 0.1, 0.05, 0.15, 0.1,
      ]));
    } catch (e) {
      debugPrint('❌ Text emotion analysis error: $e');
      setError('텍스트 감정 분석 중 오류가 발생했어요.');
    } finally {
      _isAnalyzingText = false;
      notifyListeners();
    }
  }

  /// 🧪 카메라 감정 분석 시도 시작/끝
  void startCameraAnalysis() {
    _isAnalyzingCamera = true;
    notifyListeners();
  }

  void endCameraAnalysis() {
    _isAnalyzingCamera = false;
    notifyListeners();
  }
}