import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/foundation.dart';

class EmotionAPIService {
  // 서버 URL 설정 (개발 환경)
  static const String _baseUrl = 'http://localhost:5001';
  
  // 실제 디바이스에서 테스트할 때는 서버의 IP 주소로 변경
  // static const String _baseUrl = 'http://192.168.1.100:5001';
  
  // 타임아웃 설정
  static const Duration _timeout = Duration(seconds: 10);
  
  // 서버 상태 확인
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ 서버 상태: ${data['status']}');
        print('📊 모델 로드: ${data['model_loaded']}');
        return true;
      } else {
        print('❌ 서버 상태 확인 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 서버 연결 실패: $e');
      return false;
    }
  }
  
  // 서버 정보 조회
  static Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/whoami'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📡 서버 정보: ${data['ip']}:${data['port']}');
        return data;
      } else {
        print('❌ 서버 정보 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 서버 정보 조회 실패: $e');
      return null;
    }
  }
  
  // 이미지 분석 요청 (개선된 버전)
  static Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image) async {
    try {
      print('🚀 이미지 분석 요청 시작...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      ).timeout(_timeout);
      
      print('📡 서버 응답 상태: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // Mock 모드인지 확인
        if (result['mock'] == true) {
          print('⚠️ Mock 모드로 분석 완료');
        } else {
          print('✅ 실제 모델로 분석 완료');
        }
        
        // VAD 데이터가 있는지 확인하고 없으면 생성
        if (result['vad'] == null && result['emotion'] != null) {
          result['vad'] = _generateVADFromEmotion(result['emotion'], result['confidence'] ?? 0.5);
        }
        
        print('📊 분석 결과: ${result['emotion']} (신뢰도: ${result['confidence']?.toStringAsFixed(2)})');
        return result;
        
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? '서버 오류';
        print('❌ 서버 오류: $errorMessage');
        throw Exception('서버 오류: $errorMessage');
      }
      
    } on SocketException catch (e) {
      print('❌ 네트워크 연결 실패: $e');
      throw Exception('서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.');
      
    } on TimeoutException catch (e) {
      print('❌ 요청 시간 초과: $e');
      throw Exception('요청 시간이 초과되었습니다. 네트워크 상태를 확인해주세요.');
      
    } on FormatException catch (e) {
      print('❌ 응답 파싱 오류: $e');
      throw Exception('서버 응답을 처리할 수 없습니다.');
      
    } catch (e) {
      print('❌ 예상치 못한 오류: $e');
      throw Exception('분석 중 오류가 발생했습니다: $e');
    }
  }
  
  // 감정을 VAD 값으로 변환 (서버에서 제공하지 않을 때 사용)
  static Map<String, double> _generateVADFromEmotion(String emotion, double confidence) {
    final emotionVadMap = {
      'Happy': {'valence': 0.8, 'arousal': 0.6, 'dominance': 0.7},
      'Sad': {'valence': -0.6, 'arousal': -0.3, 'dominance': -0.4},
      'Angry': {'valence': -0.7, 'arousal': 0.8, 'dominance': 0.6},
      'Fear': {'valence': -0.4, 'arousal': 0.7, 'dominance': -0.5},
      'Surprise': {'valence': 0.2, 'arousal': 0.8, 'dominance': 0.1},
      'Disgust': {'valence': -0.8, 'arousal': 0.3, 'dominance': -0.2},
      'Neutral': {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0},
    };
    
    final baseVad = emotionVadMap[emotion] ?? emotionVadMap['Neutral']!;
    final confidenceFactor = confidence * 0.3 + 0.7; // 0.7 ~ 1.0 범위
    
    return {
      'valence': baseVad['valence']! * confidenceFactor,
      'arousal': baseVad['arousal']! * confidenceFactor,
      'dominance': baseVad['dominance']! * confidenceFactor,
    };
  }
  
  // 서버 연결 테스트
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔍 서버 연결 테스트 시작...');
      
      // 1. 서버 상태 확인
      final isHealthy = await checkServerHealth();
      if (!isHealthy) {
        return {
          'success': false,
          'error': '서버가 응답하지 않습니다.',
          'details': '서버가 실행 중인지 확인해주세요.'
        };
      }
      
      // 2. 서버 정보 조회
      final serverInfo = await getServerInfo();
      if (serverInfo == null) {
        return {
          'success': false,
          'error': '서버 정보를 조회할 수 없습니다.',
          'details': '네트워크 연결을 확인해주세요.'
        };
      }
      
      // 3. 모델 목록 확인
      final modelsResponse = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      
      Map<String, dynamic> modelsInfo = {};
      if (modelsResponse.statusCode == 200) {
        final modelsData = jsonDecode(modelsResponse.body);
        modelsInfo = {
          'total_count': modelsData['total_count'],
          'models': modelsData['models'],
        };
      }
      
      return {
        'success': true,
        'server_info': serverInfo,
        'models_info': modelsInfo,
        'message': '서버 연결이 정상입니다.',
      };
      
    } catch (e) {
      return {
        'success': false,
        'error': '연결 테스트 실패',
        'details': e.toString(),
      };
    }
  }
  
  // 서버 URL 동적 변경 (개발용)
  static void setServerUrl(String newUrl) {
    print('🔧 서버 URL 변경: $_baseUrl → $newUrl');
    // 실제로는 환경 변수나 설정 파일을 통해 관리하는 것이 좋습니다.
  }
} 