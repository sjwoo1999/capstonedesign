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
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        print('🚀 이미지 분석 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/analyze_multimodal_emotion');
        
        final requestBody = {
          "face_image": base64Image,
          "audio": "",
          "text": ""
        };
        
        print('📦 요청 데이터 크기: ${base64Image.length} bytes');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10));

        print('📡 서버 응답 상태: ${response.statusCode}');
        print('📡 서버 응답 헤더: ${response.headers}');

        if (response.statusCode == 200) {
          print('✅ 이미지 분석 성공');
          final responseData = jsonDecode(response.body);
          print('📊 서버 응답 데이터: ${responseData.keys.toList()}');
          return responseData;
        } else {
          print('❌ 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 데이터 사용');
          // Mock 데이터 반환
          return {
            'emotion_tag': 'calm',
            'face_emotion': 'Neutral',
            'final_vad': {
              'valence': 0.5,
              'arousal': 0.3,
              'dominance': 0.5
            }
          };
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }

  /// 오디오 분석을 위한 새로운 메서드
  Future<Map<String, dynamic>> sendAudioForAnalysis(String base64Audio) async {
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "face_image": "",
            "audio": base64Audio,
            "text": ""
          }),
        ).timeout(const Duration(seconds: 10)); // 오디오 분석은 더 오래 걸릴 수 있음

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 오디오 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          throw Exception('오디오 분석 서버에 연결할 수 없습니다. (${maxRetryCount}회 시도 실패)');
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }

  /// 멀티모달 분석 (얼굴 + 오디오)
  Future<Map<String, dynamic>> sendMultimodalAnalysis(String base64Image, String base64Audio) async {
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "face_image": base64Image,
            "audio": base64Audio,
            "text": ""
          }),
        ).timeout(const Duration(seconds: 15)); // 멀티모달 분석은 더 오래 걸림

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 멀티모달 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          throw Exception('멀티모달 분석 서버에 연결할 수 없습니다. (${maxRetryCount}회 시도 실패)');
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }

  /// 텍스트 분석을 위한 새로운 메서드
  Future<Map<String, dynamic>> sendTextForAnalysis(String text) async {
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        print('🚀 텍스트 분석 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/analyze_multimodal_emotion');
        print('📝 분석할 텍스트: $text');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "face_image": "",
            "audio": "",
            "text": text
          }),
        ).timeout(const Duration(seconds: 10));

        print('📡 텍스트 분석 서버 응답 상태: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ 텍스트 분석 성공');
          final responseData = jsonDecode(response.body);
          print('📊 텍스트 분석 응답 데이터: ${responseData.keys.toList()}');
          return responseData;
        } else {
          print('❌ 텍스트 분석 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 텍스트 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 텍스트 VAD 데이터 사용');
          // Mock 텍스트 VAD 데이터 반환
          return {
            'text_vad': {
              'valence': 0.5,
              'arousal': 0.4,
              'dominance': 0.5
            },
            'emotion_tag': 'neutral',
            'text_emotion': 'Neutral'
          };
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }
}