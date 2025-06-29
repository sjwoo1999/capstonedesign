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

  /// 이미지 분석을 위한 메서드
  Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image) async {
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        print('🚀 이미지 분석 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/analyze_multimodal_emotion');
        print('📷 이미지 데이터 크기: ${base64Image.length} bytes');
        print('📷 이미지 데이터 미리보기: ${base64Image.substring(0, 100)}...');
        
        final requestBody = {
          "face_image": base64Image,
          "audio": "",
          "text": ""
        };
        
        print('📤 요청 본문 크기: ${jsonEncode(requestBody).length} bytes');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10));

        print('📡 이미지 분석 서버 응답 상태: ${response.statusCode}');
        print('📡 응답 헤더: ${response.headers}');

        if (response.statusCode == 200) {
          print('✅ 이미지 분석 성공');
          final responseData = jsonDecode(response.body);
          print('📊 이미지 분석 응답 데이터 키: ${responseData.keys.toList()}');
          print('📊 이미지 분석 응답 내용: ${responseData.toString().substring(0, 500)}...');
          return responseData;
        } else {
          print('❌ 이미지 분석 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 이미지 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 이미지 VAD 데이터 사용');
          // Mock 이미지 VAD 데이터 반환
          return {
            'face_emotion': 'neutral',
            'final_vad': {
              'valence': 0.5,
              'arousal': 0.5,
              'dominance': 0.5
            },
            'confidence': 0.5
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
        print('🚀 오디오 분석 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/analyze_multimodal_emotion');
        print('🎤 오디오 데이터 크기: ${base64Audio.length} bytes');
        print('🎤 오디오 데이터 미리보기: ${base64Audio.substring(0, 100)}...');
        
        final requestBody = {
          "face_image": "",
          "audio": base64Audio,
          "text": ""
        };
        
        print('📤 요청 본문 크기: ${jsonEncode(requestBody).length} bytes');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 10)); // 오디오 분석은 더 오래 걸릴 수 있음

        print('📡 오디오 분석 서버 응답 상태: ${response.statusCode}');
        print('📡 응답 헤더: ${response.headers}');

        if (response.statusCode == 200) {
          print('✅ 오디오 분석 성공');
          final responseData = jsonDecode(response.body);
          print('📊 오디오 분석 응답 데이터 키: ${responseData.keys.toList()}');
          print('📊 오디오 분석 응답 내용: ${responseData.toString().substring(0, 500)}...');
          return responseData;
        } else {
          print('❌ 오디오 분석 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 오디오 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 오디오 VAD 데이터 사용');
          // Mock 오디오 VAD 데이터 반환
          return {
            'audio_emotion': 'neutral',
            'audio_vad': {
              'valence': 0.5,
              'arousal': 0.5,
              'dominance': 0.5
            },
            'audio_confidence': 0.5
          };
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
        print('🚀 멀티모달 분석 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/analyze_multimodal_emotion');
        print('📷 이미지 데이터 크기: ${base64Image.length} bytes');
        print('🎤 오디오 데이터 크기: ${base64Audio.length} bytes');
        
        final requestBody = {
          "face_image": base64Image,
          "audio": base64Audio,
          "text": ""
        };
        
        print('📤 요청 본문 크기: ${jsonEncode(requestBody).length} bytes');
        
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 15)); // 멀티모달 분석은 더 오래 걸림

        print('📡 멀티모달 분석 서버 응답 상태: ${response.statusCode}');
        print('📡 응답 헤더: ${response.headers}');

        if (response.statusCode == 200) {
          print('✅ 멀티모달 분석 성공');
          final responseData = jsonDecode(response.body);
          print('📊 멀티모달 분석 응답 데이터 키: ${responseData.keys.toList()}');
          print('📊 멀티모달 분석 응답 내용: ${responseData.toString().substring(0, 500)}...');
          return responseData;
        } else {
          print('❌ 멀티모달 분석 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ 멀티모달 분석 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 멀티모달 VAD 데이터 사용');
          // Mock 멀티모달 VAD 데이터 반환
          return {
            'face_emotion': 'neutral',
            'audio_emotion': 'neutral',
            'final_vad': {
              'valence': 0.5,
              'arousal': 0.5,
              'dominance': 0.5
            },
            'confidence': 0.5
          };
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
            'text_emotion': 'neutral',
            'text_vad': {
              'valence': 0.5,
              'arousal': 0.5,
              'dominance': 0.5
            }
          };
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }

  /// 텍스트 감정 분석 (sendTextForAnalysis의 별칭)
  Future<Map<String, dynamic>> analyzeTextEmotion(String text) async {
    return await sendTextForAnalysis(text);
  }

  /// Gemini AI를 사용한 다음 질문 생성
  Future<Map<String, dynamic>> generateNextQuestion({
    required List<Map<String, dynamic>> conversationHistory,
    String? emotionTag,
    Map<String, double>? vadScore,
  }) async {
    int retryAttempts = 0;
    const int maxRetryCount = 3;
    const Duration retryDelay = Duration(seconds: 2);

    while (retryAttempts < maxRetryCount) {
      try {
        print('🤖 Gemini 질문 생성 요청 시도 ${retryAttempts + 1}/$maxRetryCount');
        print('📡 요청 URL: $_baseUrl/generate_question');
        print('📊 대화 히스토리 길이: ${conversationHistory.length}');
        print('😊 현재 감정: $emotionTag');
        
        final requestBody = {
          "history": conversationHistory,
          "emotion_tag": emotionTag,
          "vad_score": vadScore,
        };
        
        final response = await http.post(
          Uri.parse('$_baseUrl/generate_question'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        ).timeout(const Duration(seconds: 15)); // AI 생성은 더 오래 걸릴 수 있음

        print('📡 Gemini 질문 생성 서버 응답 상태: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Gemini 질문 생성 성공');
          final responseData = jsonDecode(response.body);
          print('🤖 생성된 질문: ${responseData['question']}');
          return responseData;
        } else {
          print('❌ Gemini 질문 생성 서버 오류 응답: ${response.body}');
          throw Exception(
              '서버 오류: ${response.statusCode} ${response.reasonPhrase}');
        }
      } catch (e) {
        retryAttempts++;
        print('❗ Gemini 질문 생성 서버 연결 실패 [시도 $retryAttempts/$maxRetryCount]: $e');

        if (retryAttempts >= maxRetryCount) {
          print('❌ 최대 재시도 횟수 초과, Mock 질문 사용');
          // Mock 질문 반환
          return {
            'success': true,
            'question': _getMockQuestion(conversationHistory.length, emotionTag),
            'model': 'mock',
            'conversation_length': conversationHistory.length,
            'emotion_tag': emotionTag
          };
        }

        await Future.delayed(retryDelay);
      }
    }

    throw Exception('예상치 못한 오류 발생');
  }

  /// Mock 질문 생성 (API 실패 시 사용)
  String _getMockQuestion(int conversationLength, String? emotionTag) {
    final mockQuestions = [
      "오늘 하루 중 가장 기뻤던 순간은 언제였나요?",
      "최근에 힘들었던 일은 무엇인가요?",
      "지금 기분을 한 단어로 표현한다면?",
      "가장 위로가 되는 것은 무엇인가요?",
      "지금 가장 하고 싶은 것은 무엇인가요?",
      "오늘 하루를 어떻게 보내고 싶으신가요?",
      "가장 감사한 것은 무엇인가요?",
      "지금 가장 필요한 것은 무엇인가요?",
      "어떤 일이 가장 스트레스가 되나요?",
      "기분이 좋아지는 방법은 무엇인가요?"
    ];
    
    // 감정별 특화 질문
    final emotionSpecificQuestions = {
      'angry': "지금 어떤 상황이 가장 화가 나게 만드나요?",
      'sad': "지금 가장 슬프게 만드는 것은 무엇인가요?",
      'anxious': "지금 가장 걱정되는 것은 무엇인가요?",
      'happy': "지금 기분이 좋은 이유는 무엇인가요?",
      'neutral': "오늘 하루는 어땠나요?"
    };
    
    // 감정별 질문이 있으면 사용, 없으면 일반 질문 사용
    if (emotionTag != null && emotionSpecificQuestions.containsKey(emotionTag)) {
      return emotionSpecificQuestions[emotionTag]!;
    }
    
    // 대화 길이에 따라 질문 선택
    final questionIndex = conversationLength % mockQuestions.length;
    return mockQuestions[questionIndex];
  }
}