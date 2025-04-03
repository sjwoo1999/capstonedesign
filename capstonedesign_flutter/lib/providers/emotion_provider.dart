// 📂 lib/providers/emotion_provider.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider extends ChangeNotifier {
  /// 🔹 감정 분석 결과 객체 (Flask API or 로컬)
  EmotionResult? _result;
  EmotionResult? get result => _result;

  /// 🔹 감정 분석 중 여부 (텍스트 기반 분석일 때 사용)
  bool _isAnalyzingText = false;
  bool get isAnalyzingText => _isAnalyzingText;

  /// 🔹 감정 분석 실패 시 사용자에게 보여줄 메시지
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ────────────────────────────────────────────────────────────────
  /// ✅ 감정 분석 결과 설정 (로컬 분석 또는 API 성공 결과)
  void setResult(EmotionResult result) {
    _result = result;
    _errorMessage = null;
    notifyListeners();
  }

  /// ✅ Flask API 응답 처리 전용 (Map → EmotionResult 변환)
  void setResultFromApi(Map<String, dynamic> json) {
    _result = EmotionResult.fromApi(json);
    _errorMessage = null;
    notifyListeners();
  }

  /// ❌ 분석 실패 시 사용자에게 보여줄 에러 메시지 설정
  void setError(String message) {
    _result = null;
    _errorMessage = message;
    notifyListeners();
  }

  /// ✅ 에러 메시지만 초기화 (UI 갱신)
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 🔄 결과 초기화 (결과 + 에러 모두 제거)
  void clear() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────
  /// 🧪 예시용: 텍스트 기반 감정 분석 흐름
  Future<void> analyze({required String text}) async {
    _isAnalyzingText = true;
    notifyListeners();

    try {
      // ✅ 실제 감정 분석 로직 (예: OpenAI API, Flask API 등)으로 교체 가능
      await Future.delayed(const Duration(seconds: 2));

      // ✅ 예시 결과로 로컬 감정 분석 결과 설정
      setResult(EmotionResult.fromLocal([
        0.3, 0.2, 0.1, 0.1, 0.05, 0.15, 0.1, // 감정 점수
      ]));
    } catch (e) {
      debugPrint('❌ Text emotion analysis error: $e');
      setError('텍스트 감정 분석 중 오류가 발생했어요.');
    } finally {
      _isAnalyzingText = false;
      notifyListeners();
    }
  }
}
