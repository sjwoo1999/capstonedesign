// lib/providers/emotion_provider.dart
import 'package:flutter/material.dart';
import '../models/emotion_result.dart';
import '../models/emotion_data_point.dart';
import '../models/multimodal_data_point.dart';
import '../services/multimodal_analysis_service.dart';

class EmotionProvider with ChangeNotifier {
  EmotionResult? result;
  String? errorMessage;
  bool isAnalyzing = false;
  bool _onboardingCompleted = false;

  // 🆕 멀티모달 분석 서비스
  final MultimodalAnalysisService _multimodalService = MultimodalAnalysisService();

  // 🆕 세션 중 수집된 결과들
  List<EmotionResult> sessionResults = [];
  List<EmotionDataPoint> sessionDataPoints = [];
  List<MultimodalDataPoint> sessionMultimodalData = [];

  // 🆕 분석 세션 활성화 여부
  bool isSessionActive = false;

  // 🆕 전체 앱 실행 중 누적 기록 (메모리 기반)
  List<EmotionResult> historyList = [];
  List<EmotionDataPoint> historyDataPoints = [];
  List<MultimodalDataPoint> historyMultimodalData = [];

  // 🆕 현재 수집 중인 데이터
  String? currentImageData;
  String? currentAudioData;
  String? currentTextData;

  // 온보딩 완료 상태
  bool get onboardingCompleted => _onboardingCompleted;

  void setOnboardingCompleted(bool completed) {
    _onboardingCompleted = completed;
    notifyListeners();
  }

  void startCameraAnalysis() {
    isAnalyzing = true;
    notifyListeners();
  }

  void endCameraAnalysis() {
    isAnalyzing = false;
    notifyListeners();
  }

  void setResultFromApi(Map<String, dynamic> data) {
    result = EmotionResult.fromApi(data);
    if (isSessionActive && result != null) {
      sessionResults.add(result!);
    }
    notifyListeners();
  }

  void setError(String message) {
    errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // 🆕 멀티모달 데이터 수집 메서드들
  void setImageData(String? base64Image) {
    currentImageData = base64Image;
    print('📷 [Provider] 이미지 데이터 설정: ${base64Image != null ? "있음 (${base64Image.length} bytes)" : "없음"}');
    if (base64Image != null) {
      print('📷 [Provider] 이미지 데이터 미리보기: ${base64Image.substring(0, 100)}...');
    }
  }

  void setAudioData(String? base64Audio) {
    currentAudioData = base64Audio;
    print('🎤 [Provider] 오디오 데이터 설정: ${base64Audio != null ? "있음 (${base64Audio.length} bytes)" : "없음"}');
    if (base64Audio != null) {
      final previewLength = base64Audio.length < 100 ? base64Audio.length : 100;
      print('🎤 [Provider] 오디오 데이터 미리보기: ${base64Audio.substring(0, previewLength)}...');
    }
  }

  void setTextData(String? text) {
    currentTextData = text;
    print('📝 [Provider] 텍스트 데이터 설정: ${text != null ? "있음" : "없음"}');
    if (text != null) {
      print('📝 [Provider] 텍스트 내용: "$text"');
    }
  }

  // 🆕 멀티모달 분석 실행
  Future<EmotionDataPoint?> performMultimodalAnalysis({
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🚀 [Provider] 멀티모달 분석 시작');
      print('📊 [Provider] 현재 수집된 데이터:');
      print('   - 이미지: ${currentImageData != null ? "있음 (${currentImageData!.length} bytes)" : "없음"}');
      print('   - 오디오: ${currentAudioData != null ? "있음 (${currentAudioData!.length} bytes)" : "없음"}');
      print('   - 텍스트: ${currentTextData != null ? "있음" : "없음"}');
      print('   - 세션 ID: $sessionId');
      print('   - 메타데이터: $metadata');
      
      // 현재 수집된 데이터로 분석 실행
      final multimodalResult = await _multimodalService.analyzeMultimodal(
        base64Image: currentImageData,
        base64Audio: currentAudioData,
        text: currentTextData,
        sessionId: sessionId,
        metadata: metadata,
      );

      print('✅ [Provider] 멀티모달 분석 완료');
      print('📊 [Provider] 분석 결과:');
      print('   - 사용된 모달리티: ${multimodalResult.availableModalities}개');
      print('   - 최종 감정: ${multimodalResult.finalEmotion}');
      print('   - 최종 신뢰도: ${multimodalResult.finalConfidence}');
      print('   - VAD: (${multimodalResult.finalValence}, ${multimodalResult.finalArousal}, ${multimodalResult.finalDominance})');

      // EmotionDataPoint로 변환
      final emotionDataPoint = EmotionDataPoint.fromMultimodal(multimodalResult);

      // 세션 중이면 결과 저장
      if (isSessionActive) {
        sessionMultimodalData.add(multimodalResult);
        sessionDataPoints.add(emotionDataPoint);
        print('💾 [Provider] 세션 데이터에 결과 저장됨');
      }

      // 결과 설정
      result = EmotionResult.fromMultimodalData(multimodalResult);
      
      print('✅ [Provider] 멀티모달 분석 완료: ${multimodalResult.availableModalities}개 모달리티');
      notifyListeners();
      
      return emotionDataPoint;
    } catch (e) {
      print('❌ [Provider] 멀티모달 분석 실패: $e');
      setError('멀티모달 분석 중 오류가 발생했습니다: $e');
      return null;
    }
  }

  // 🆕 실시간 멀티모달 분석 (스트리밍)
  Stream<EmotionDataPoint> streamMultimodalAnalysis({
    String? sessionId,
    Duration interval = const Duration(seconds: 2),
  }) {
    return Stream.periodic(interval).asyncMap((_) async {
      final dataPoint = await performMultimodalAnalysis(sessionId: sessionId);
      return dataPoint ?? EmotionDataPoint.mock();
    });
  }

  // 🆕 세션 시작
  void startSession() {
    sessionResults.clear();
    sessionDataPoints.clear();
    sessionMultimodalData.clear();
    currentImageData = null;
    currentAudioData = null;
    currentTextData = null;
    isSessionActive = true;
    notifyListeners();
  }

  // 🆕 세션 종료 → 평균 결과 반환
  EmotionResult endSession() {
    isSessionActive = false;

    if (sessionResults.isEmpty && sessionDataPoints.isEmpty) {
      // 아무 데이터 없으면 neutral 리턴
      return EmotionResult(
        probabilities: {
          'happy': 0,
          'sad': 0,
          'angry': 0,
          'surprised': 0,
          'disgust': 0,
          'fear': 0,
          'neutral': 1,
        },
        feedback: '',
      );
    }

    // 멀티모달 데이터가 있으면 그것을 우선 사용
    if (sessionDataPoints.isNotEmpty) {
      final avgDataPoint = _calculateAverageDataPoint(sessionDataPoints);
      final sessionResult = EmotionResult.fromEmotionDataPoint(avgDataPoint);
      saveSessionResult(sessionResult);
      saveSessionDataPoint(avgDataPoint);
      return sessionResult;
    }

    // 기존 방식으로 평균 계산
    final Map<String, double> sum = {
      'happy': 0,
      'sad': 0,
      'angry': 0,
      'surprised': 0,
      'disgust': 0,
      'fear': 0,
      'neutral': 0,
    };
    for (var r in sessionResults) {
      r.probabilities.forEach((key, value) {
        sum[key] = (sum[key] ?? 0) + value;
      });
    }
    final avg = sum.map((key, value) => MapEntry(key, value / sessionResults.length));

    final sessionResult = EmotionResult(probabilities: avg, feedback: '');

    // ✅ 세션이 끝날 때 평균 결과를 historyList에 저장
    saveSessionResult(sessionResult);

    return sessionResult;
  }

  // 🆕 EmotionDataPoint 평균 계산
  EmotionDataPoint _calculateAverageDataPoint(List<EmotionDataPoint> dataPoints) {
    if (dataPoints.isEmpty) {
      return EmotionDataPoint.mock();
    }

    double sumValence = 0.0;
    double sumArousal = 0.0;
    double sumDominance = 0.0;
    double sumConfidence = 0.0;

    for (final dataPoint in dataPoints) {
      sumValence += dataPoint.valence;
      sumArousal += dataPoint.arousal;
      sumDominance += dataPoint.dominance;
      sumConfidence += dataPoint.confidence ?? 0.5;
    }

    final avgValence = sumValence / dataPoints.length;
    final avgArousal = sumArousal / dataPoints.length;
    final avgDominance = sumDominance / dataPoints.length;
    final avgConfidence = sumConfidence / dataPoints.length;

    // 가장 빈번한 감정 찾기
    final emotionCounts = <String, int>{};
    for (final dataPoint in dataPoints) {
      if (dataPoint.emotion != null) {
        emotionCounts[dataPoint.emotion!] = (emotionCounts[dataPoint.emotion!] ?? 0) + 1;
      }
    }

    String mostFrequentEmotion = 'neutral';
    int maxCount = 0;
    emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentEmotion = emotion;
      }
    });

    return EmotionDataPoint(
      timestamp: DateTime.now(),
      valence: avgValence,
      arousal: avgArousal,
      dominance: avgDominance,
      emotion: mostFrequentEmotion,
      confidence: avgConfidence,
    );
  }

  // 🆕 세션 결과 저장 (메모리 누적)
  void saveSessionResult(EmotionResult result) {
    historyList.add(result);
    notifyListeners();
  }

  // 🆕 EmotionDataPoint 저장
  void saveSessionDataPoint(EmotionDataPoint dataPoint) {
    historyDataPoints.add(dataPoint);
    notifyListeners();
  }

  // 🆕 MultimodalDataPoint 저장
  void saveSessionMultimodalData(MultimodalDataPoint multimodalData) {
    historyMultimodalData.add(multimodalData);
    notifyListeners();
  }

  // 🆕 분석 품질 평가
  double get currentAnalysisQuality {
    if (sessionDataPoints.isEmpty) return 0.0;
    
    double totalQuality = 0.0;
    for (final dataPoint in sessionDataPoints) {
      totalQuality += dataPoint.analysisQuality;
    }
    return totalQuality / sessionDataPoints.length;
  }

  // 🆕 사용 가능한 모달리티 정보
  String get availableModalitiesInfo {
    int visualCount = 0;
    int audioCount = 0;
    int textCount = 0;

    for (final dataPoint in sessionDataPoints) {
      if (dataPoint.hasModality('visual')) visualCount++;
      if (dataPoint.hasModality('audio')) audioCount++;
      if (dataPoint.hasModality('text')) textCount++;
    }

    final modalities = <String>[];
    if (visualCount > 0) modalities.add('영상($visualCount)');
    if (audioCount > 0) modalities.add('음성($audioCount)');
    if (textCount > 0) modalities.add('텍스트($textCount)');

    return modalities.isEmpty ? '없음' : modalities.join(', ');
  }
}
