import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/multimodal_data_point.dart';
import 'emotion_api_services.dart';

/// 멀티모달 감정 분석 서비스
/// 영상, 음성, 텍스트 세 가지 모달리티를 통합하여 분석
class MultimodalAnalysisService {
  static String _baseUrl = dotenv.env['EMOTION_API_URL'] ?? 'http://localhost:5001';
  final EmotionAPIService _emotionApiService;
  
  MultimodalAnalysisService({
    EmotionAPIService? emotionApiService,
  }) : _emotionApiService = emotionApiService ?? EmotionAPIService();

  /// 🔧 동적으로 BaseURL 설정 가능
  static void setBaseUrl(String url) {
    _baseUrl = url;
    print('📡 Multimodal API 서버 주소 설정됨: $_baseUrl');
  }

  /// 완전한 멀티모달 분석 (영상 + 음성 + 텍스트)
  Future<MultimodalDataPoint> analyzeMultimodal({
    String? base64Image,
    String? base64Audio,
    String? text,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    print('🚀 멀티모달 분석 시작');
    print('📊 입력 데이터: 영상=${base64Image != null ? "있음" : "없음"}, 음성=${base64Audio != null ? "있음" : "없음"}, 텍스트=${text != null ? "있음" : "없음"}');

    final timestamp = DateTime.now();
    ModalityData? visualData;
    ModalityData? audioData;
    ModalityData? textData;

    // 병렬로 각 모달리티 분석 실행
    final futures = <Future<void>>[];

    // 1. 영상 분석
    if (base64Image != null && base64Image.isNotEmpty) {
      futures.add(_analyzeVisual(base64Image).then((data) => visualData = data));
    }

    // 2. 음성 분석
    if (base64Audio != null && base64Audio.isNotEmpty) {
      futures.add(_analyzeAudio(base64Audio).then((data) => audioData = data));
    }

    // 3. 텍스트 분석
    if (text != null && text.isNotEmpty) {
      futures.add(_analyzeText(text).then((data) => textData = data));
    }

    // 모든 분석 완료 대기
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }

    // 통합된 멀티모달 데이터 포인트 생성
    final multimodalData = MultimodalDataPoint.fromModalities(
      timestamp: timestamp,
      visualData: visualData,
      audioData: audioData,
      textData: textData,
      sessionId: sessionId,
      metadata: metadata,
    );

    print('✅ 멀티모달 분석 완료: ${multimodalData.availableModalities}개 모달리티, 최종감정: ${multimodalData.finalEmotion}');
    return multimodalData;
  }

  /// 영상 분석
  Future<ModalityData?> _analyzeVisual(String base64Image) async {
    try {
      print('📷 영상 분석 시작');
      final response = await _emotionApiService.sendImageForAnalysis(base64Image);
      
      if (response.containsKey('face_emotion') && response.containsKey('final_vad')) {
        final vad = response['final_vad'] as Map<String, dynamic>;
        return ModalityData(
          valence: vad['valence']?.toDouble(),
          arousal: vad['arousal']?.toDouble(),
          dominance: vad['dominance']?.toDouble(),
          emotion: response['face_emotion'],
          confidence: response['confidence']?.toDouble() ?? 0.8,
          rawData: base64Image,
        );
      }
    } catch (e) {
      print('❌ 영상 분석 실패: $e');
    }
    return null;
  }

  /// 음성 분석
  Future<ModalityData?> _analyzeAudio(String base64Audio) async {
    try {
      print('🎤 음성 분석 시작');
      final response = await _emotionApiService.sendAudioForAnalysis(base64Audio);
      
      if (response.containsKey('audio_emotion') && response.containsKey('audio_vad')) {
        final vad = response['audio_vad'] as Map<String, dynamic>;
        return ModalityData(
          valence: vad['valence']?.toDouble(),
          arousal: vad['arousal']?.toDouble(),
          dominance: vad['dominance']?.toDouble(),
          emotion: response['audio_emotion'],
          confidence: response['audio_confidence']?.toDouble() ?? 0.7,
          rawData: base64Audio,
        );
      }
    } catch (e) {
      print('❌ 음성 분석 실패: $e');
    }
    return null;
  }

  /// 텍스트 분석
  Future<ModalityData?> _analyzeText(String text) async {
    try {
      print('📝 텍스트 분석 시작');
      final response = await _emotionApiService.sendTextForAnalysis(text);
      
      if (response.containsKey('text_emotion') && response.containsKey('text_vad')) {
        final vad = response['text_vad'] as Map<String, dynamic>;
        return ModalityData(
          valence: vad['valence']?.toDouble(),
          arousal: vad['arousal']?.toDouble(),
          dominance: vad['dominance']?.toDouble(),
          emotion: response['text_emotion'],
          confidence: response['text_confidence']?.toDouble() ?? 0.6,
          rawData: text,
        );
      }
    } catch (e) {
      print('❌ 텍스트 분석 실패: $e');
    }
    return null;
  }

  /// 서버에 직접 멀티모달 분석 요청 (서버에서 통합 분석 지원 시)
  Future<MultimodalDataPoint?> _analyzeMultimodalOnServer({
    String? base64Image,
    String? base64Audio,
    String? text,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🌐 서버 멀티모달 분석 요청');
      
      final requestBody = {
        "face_image": base64Image ?? "",
        "audio": base64Audio ?? "",
        "text": text ?? "",
        if (sessionId != null) "session_id": sessionId,
        if (metadata != null) "metadata": metadata,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/analyze_multimodal_emotion'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return _parseServerMultimodalResponse(responseData, sessionId, metadata);
      } else {
        print('❌ 서버 멀티모달 분석 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 서버 멀티모달 분석 오류: $e');
      return null;
    }
  }

  /// 서버 응답을 MultimodalDataPoint로 파싱
  MultimodalDataPoint? _parseServerMultimodalResponse(
    Map<String, dynamic> response,
    String? sessionId,
    Map<String, dynamic>? metadata,
  ) {
    try {
      ModalityData? visualData;
      ModalityData? audioData;
      ModalityData? textData;

      // 영상 데이터 파싱
      if (response.containsKey('visual_analysis')) {
        final visual = response['visual_analysis'] as Map<String, dynamic>;
        visualData = ModalityData(
          valence: visual['valence']?.toDouble(),
          arousal: visual['arousal']?.toDouble(),
          dominance: visual['dominance']?.toDouble(),
          emotion: visual['emotion'],
          confidence: visual['confidence']?.toDouble(),
        );
      }

      // 음성 데이터 파싱
      if (response.containsKey('audio_analysis')) {
        final audio = response['audio_analysis'] as Map<String, dynamic>;
        audioData = ModalityData(
          valence: audio['valence']?.toDouble(),
          arousal: audio['arousal']?.toDouble(),
          dominance: audio['dominance']?.toDouble(),
          emotion: audio['emotion'],
          confidence: audio['confidence']?.toDouble(),
        );
      }

      // 텍스트 데이터 파싱
      if (response.containsKey('text_analysis')) {
        final text = response['text_analysis'] as Map<String, dynamic>;
        textData = ModalityData(
          valence: text['valence']?.toDouble(),
          arousal: text['arousal']?.toDouble(),
          dominance: text['dominance']?.toDouble(),
          emotion: text['emotion'],
          confidence: text['confidence']?.toDouble(),
        );
      }

      // 통합 결과 파싱
      final finalVad = response['final_vad'] as Map<String, dynamic>;
      
      return MultimodalDataPoint(
        timestamp: DateTime.now(),
        visualData: visualData,
        audioData: audioData,
        textData: textData,
        finalValence: finalVad['valence']?.toDouble() ?? 0.0,
        finalArousal: finalVad['arousal']?.toDouble() ?? 0.0,
        finalDominance: finalVad['dominance']?.toDouble() ?? 0.0,
        finalEmotion: response['final_emotion'] ?? 'neutral',
        finalConfidence: response['final_confidence']?.toDouble() ?? 0.0,
        sessionId: sessionId,
        metadata: metadata,
      );
    } catch (e) {
      print('❌ 서버 응답 파싱 실패: $e');
      return null;
    }
  }

  /// 실시간 스트리밍 멀티모달 분석 (세션 중 지속적 분석)
  Stream<MultimodalDataPoint> streamMultimodalAnalysis({
    required Stream<String?> imageStream,
    required Stream<String?> audioStream,
    required Stream<String?> textStream,
    String? sessionId,
    Duration interval = const Duration(seconds: 2),
  }) {
    return Stream.periodic(interval).asyncMap((_) async {
      // 각 스트림의 최신 값들을 수집
      String? latestImage;
      String? latestAudio;
      String? latestText;

      // 최신 값들을 가져오는 로직 (실제 구현에서는 적절한 방법 사용)
      
      return await analyzeMultimodal(
        base64Image: latestImage,
        base64Audio: latestAudio,
        text: latestText,
        sessionId: sessionId,
      );
    });
  }

  /// Mock 멀티모달 데이터 생성 (테스트용)
  MultimodalDataPoint generateMockMultimodalData({
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    return MultimodalDataPoint.mock();
  }

  /// 분석 품질 평가
  double evaluateAnalysisQuality(MultimodalDataPoint dataPoint) {
    double quality = 0.0;
    int modalityCount = 0;

    // 각 모달리티별 품질 평가
    if (dataPoint.visualData != null) {
      quality += dataPoint.visualData!.confidence ?? 0.5;
      modalityCount++;
    }
    if (dataPoint.audioData != null) {
      quality += dataPoint.audioData!.confidence ?? 0.5;
      modalityCount++;
    }
    if (dataPoint.textData != null) {
      quality += dataPoint.textData!.confidence ?? 0.5;
      modalityCount++;
    }

    // 모달리티 개수에 따른 보너스
    if (modalityCount > 1) {
      quality += (modalityCount - 1) * 0.1; // 추가 모달리티당 10% 보너스
    }

    return modalityCount > 0 ? quality / modalityCount : 0.0;
  }

  /// 분석 결과 요약
  String generateAnalysisSummary(MultimodalDataPoint dataPoint) {
    final quality = evaluateAnalysisQuality(dataPoint);
    final modalities = dataPoint.availableModalities;
    
    return '''
멀티모달 감정 분석 결과:
- 사용된 모달리티: $modalities개
- 최종 감정: ${dataPoint.finalEmotion}
- 신뢰도: ${(dataPoint.finalConfidence * 100).toStringAsFixed(1)}%
- 분석 품질: ${(quality * 100).toStringAsFixed(1)}%
- VAD: (${dataPoint.finalValence.toStringAsFixed(2)}, ${dataPoint.finalArousal.toStringAsFixed(2)}, ${dataPoint.finalDominance.toStringAsFixed(2)})
''';
  }
} 