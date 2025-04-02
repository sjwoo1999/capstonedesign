import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider extends ChangeNotifier {
  EmotionResult? _result;
  EmotionResult? get result => _result;

  bool _isAnalyzingText = false;
  bool get isAnalyzingText => _isAnalyzingText;

  /// 로컬 모델 결과 설정 (기존 유지)
  void setResult(EmotionResult result) {
    _result = result;
    notifyListeners();
  }

  /// 🆕 Flask API 결과 설정용 메서드
  void setResultFromApi(Map<String, dynamic> json) {
    _result = EmotionResult.fromApi(json);
    notifyListeners();
  }

  void clear() {
    _result = null;
    notifyListeners();
  }

  /// 예시 텍스트 감정 분석 흐름
  Future<void> analyze({required String text}) async {
    _isAnalyzingText = true;
    notifyListeners();

    try {
      // 실제 감정 분석 로직 들어갈 자리 (예: OpenAI API, Flask 서버 등)
      await Future.delayed(const Duration(seconds: 2));

      // 예시 결과 (실제로는 API 응답 등으로 대체)
      setResult(EmotionResult.fromLocal([
        0.3, 0.2, 0.1, 0.1, 0.05, 0.15, 0.1, // 감정 점수
      ]));
    } catch (e) {
      debugPrint('Text emotion analysis error: $e');
    } finally {
      _isAnalyzingText = false;
      notifyListeners();
    }
  }
}
