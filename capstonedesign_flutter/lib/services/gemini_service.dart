import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static const String _baseUrl = 'http://192.168.219.108:5001';
  
  // 대화 컨텍스트를 유지하기 위한 메시지 히스토리
  List<Map<String, String>> _conversationHistory = [];
  
  // Gemini API 호출 (서버를 통해)
  Future<String> getResponse(String userMessage) async {
    try {
      // 대화 히스토리에 사용자 메시지 추가
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });
      
      // 서버 API 호출
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/gemini'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': userMessage,
          'conversation_history': _conversationHistory,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          final aiResponse = data['response'];
          
          // 대화 히스토리에 AI 응답 추가
          _conversationHistory.add({
            'role': 'model',
            'content': aiResponse,
          });
          
          // 서버에서 업데이트된 대화 히스토리 사용
          if (data['conversation_history'] != null) {
            _conversationHistory = List<Map<String, String>>.from(
              data['conversation_history'].map((msg) => {
                'role': msg['role'],
                'content': msg['content'],
              })
            );
          }
          
          // 대화 히스토리가 너무 길어지면 오래된 메시지 제거
          if (_conversationHistory.length > 10) {
            _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 8);
          }
          
          return aiResponse;
        } else {
          throw Exception(data['error'] ?? '서버에서 오류가 발생했습니다');
        }
      } else {
        throw Exception('서버 연결 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Gemini API 오류: $e');
      return '죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다.\n\n오류: $e';
    }
  }
  
  // 대화 히스토리 초기화
  Future<void> clearConversation() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/chat/gemini/clear'),
        headers: {
          'Content-Type': 'application/json',
        },
      );
      _conversationHistory.clear();
    } catch (e) {
      print('❌ 대화 초기화 오류: $e');
      _conversationHistory.clear();
    }
  }
  
  // 대화 히스토리 가져오기
  List<Map<String, String>> getConversationHistory() {
    return List.from(_conversationHistory);
  }
  
  // 시스템 프롬프트 설정
  void setSystemPrompt(String prompt) {
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'user',
      'content': prompt,
    });
  }
  
  // 서비스 상태 확인
  Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/gemini/status'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['available'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ 서비스 상태 확인 오류: $e');
      return false;
    }
  }
} 