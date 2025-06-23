import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmotionAPIService {
  static String _baseUrl = dotenv.env['EMOTION_API_URL'] ?? 'http://localhost:5001';
  final int maxRetryCount;
  final Duration retryDelay;

  EmotionAPIService({
    String? customUrl,
    this.maxRetryCount = 3,
    this.retryDelay = const Duration(seconds: 2),
  }) {
    if (customUrl != null) {
      _baseUrl = customUrl;
    }
  }

  /// 🔧 동적으로 BaseURL 설정 가능 (예: 서버 탐색 이후)
  static void setBaseUrl(String url) {
    _baseUrl = url;
    print('📡 Emotion API 서버 주소 설정됨: $_baseUrl');
  }

  Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image) async {
    // [개발용 목업] - 실제 서버가 불안정할 때 사용합니다.
    // true로 바꾸면 실제 서버 요청 대신 아래의 가짜 데이터를 즉시 반환합니다.
    const bool useMockData = true; 
    if (useMockData) {
      print('🚧 DEVELOPMENT MODE: Mock API Response 사용 중 🚧');
      await Future.delayed(const Duration(milliseconds: 800)); // 실제 네트워크처럼 보이게 살짝 지연
      return {
        "status": "success",
        "vad": {
          "valence": (Random().nextDouble() * 2 - 1),
          "arousal": (Random().nextDouble() * 2 - 1),
          "dominance": (Random().nextDouble() * 2 - 1)
        }
      };
    }

    int retryAttempts = 0;

    while (retryAttempts < maxRetryCount) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/predict'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"image": base64Image}),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          throw Exception('서버에 연결할 수 없습니다. (${maxRetryCount}회 시도 실패)');
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }
}