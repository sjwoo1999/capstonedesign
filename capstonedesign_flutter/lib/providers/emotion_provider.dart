import 'package:flutter/material.dart';
import '../models/emotion_result.dart';

class EmotionProvider extends ChangeNotifier {
  EmotionResult? _result;
  EmotionResult? get result => _result;

  bool _isAnalyzingText = false;
  bool get isAnalyzingText => _isAnalyzingText;

  void setResult(EmotionResult result) {
    _result = result;
    notifyListeners();
  }

  void clear() {
    _result = null;
    notifyListeners();
  }

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
