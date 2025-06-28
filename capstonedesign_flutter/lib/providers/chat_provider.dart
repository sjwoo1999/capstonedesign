import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
import '../services/audio_manager.dart';

class ChatProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final AudioManager _audioManager = AudioManager();
  final Uuid _uuid = Uuid();
  
  List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isProcessing = false;
  String _currentUserInput = '';
  
  final List<String> _loadingMessages = [
    "생각을 정리하고 있어요...",
    "조금만 기다려 주세요, 답변을 준비 중이에요!",
    "곧 답변을 드릴게요 :)",
    "당신의 이야기를 곰곰이 생각하고 있어요...",
    "좋은 답변을 고민 중이에요, 잠시만요!"
  ];
  
  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  String get currentUserInput => _currentUserInput;
  
  ChatProvider() {
    _initializeAudioManager();
  }
  
  void _initializeAudioManager() {
    _audioManager.initialize();
    _audioManager.onTextRecognized = _handleUserInput;
    _audioManager.onStatusChanged = _handleAudioStatusChange;
  }
  
  // 사용자 음성 입력 처리
  void _handleUserInput(String text) {
    if (text.trim().isNotEmpty) {
      _currentUserInput = text;
      notifyListeners();
      
      // 자동으로 메시지 전송
      _sendMessage(text);
    }
  }
  
  // 오디오 상태 변경 처리
  void _handleAudioStatusChange(String status) {
    _isListening = status == 'listening';
    notifyListeners();
  }
  
  // 메시지 전송
  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    // 사용자 메시지 추가
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    _currentUserInput = '';
    _isProcessing = true;
    
    // 1. 임시 로딩 메시지 추가 (랜덤)
    final loadingMessage = ChatMessage(
      id: _uuid.v4(),
      content: (_loadingMessages..shuffle()).first,
      type: MessageType.ai,
      timestamp: DateTime.now(),
      isProcessing: true,
    );
    _messages.add(loadingMessage);
    
    notifyListeners();
    
    // AI 응답 요청
    try {
      final aiResponse = await _geminiService.getResponse(content);
      
      // 2. 임시 메시지 제거
      _messages.removeWhere((msg) => msg.isProcessing);
      
      // 3. 실제 AI 메시지 추가
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: aiResponse,
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );
      _messages.add(aiMessage);
    } catch (e) {
      _messages.removeWhere((msg) => msg.isProcessing);
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: '죄송합니다. 응답을 생성하는 중에 오류가 발생했습니다.',
        type: MessageType.ai,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    }
    
    _isProcessing = false;
    notifyListeners();
  }
  
  // 음성 인식 시작
  Future<void> startListening() async {
    if (_isProcessing) return;
    
    try {
      await _audioManager.startSTT();
      _isListening = true;
      notifyListeners();
    } catch (e) {
      print('❌ 음성 인식 시작 실패: $e');
    }
  }
  
  // 음성 인식 중지
  Future<void> stopListening() async {
    try {
      await _audioManager.stopSTT();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      print('❌ 음성 인식 중지 실패: $e');
    }
  }
  
  // 텍스트로 메시지 전송
  Future<void> sendTextMessage(String text) async {
    await _sendMessage(text);
  }
  
  // 대화 초기화
  Future<void> clearConversation() async {
    _messages.clear();
    _currentUserInput = '';
    _isProcessing = false;
    await _geminiService.clearConversation();
    notifyListeners();
  }
  
  // 시스템 프롬프트 설정
  void setSystemPrompt(String prompt) {
    _geminiService.setSystemPrompt(prompt);
  }
  
  // 대화 내보내기
  List<Map<String, dynamic>> exportConversation() {
    return _messages.map((msg) => msg.toJson()).toList();
  }
  
  @override
  void dispose() {
    _audioManager.dispose();
    super.dispose();
  }
} 