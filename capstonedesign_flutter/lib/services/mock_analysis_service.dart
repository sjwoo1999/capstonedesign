import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/emotion_data_point.dart';
import '../models/vad_emotion.dart';
import '../models/cbt_feedback.dart';

class MockAnalysisService {
  static const Map<String, String> _emotionCategories = {
    'joy': '기쁨',
    'sadness': '슬픔',
    'anger': '화남',
    'fear': '두려움',
    'surprise': '놀람',
    'disgust': '혐오',
    'neutral': '중립',
    'excitement': '흥미',
    'calm': '평온',
    'anxiety': '불안',
  };

  static const Map<String, String> _emotionIcons = {
    'joy': '😄',
    'sadness': '😢',
    'anger': '😠',
    'fear': '😨',
    'surprise': '😲',
    'disgust': '🤢',
    'neutral': '😐',
    'excitement': '😃',
    'calm': '😌',
    'anxiety': '😰',
  };

  /// 수집된 VAD 데이터를 기반으로 즉시 분석 결과 생성
  static Map<String, dynamic> analyzeSessionData(List<EmotionDataPoint> sessionData) {
    if (sessionData.isEmpty) {
      return _generateEmptyAnalysis();
    }

    // 1. VAD 통계 계산
    final vadStats = _calculateVADStats(sessionData);
    
    // 2. 감정 카테고리 결정
    final emotionCategory = _determineEmotionCategory(vadStats);
    
    // 3. 감정 변화 패턴 분석
    final emotionPattern = _analyzeEmotionPattern(sessionData);
    
    // 4. CBT 피드백 생성
    final cbtFeedback = _generateCBTFeedback(vadStats, emotionPattern);
    
    // 5. 개선 제안 생성
    final recommendations = _generateRecommendations(vadStats, emotionPattern);

    return {
      'analysis': {
        'timestamp': DateTime.now().toIso8601String(),
        'sessionDuration': _calculateSessionDuration(sessionData).inSeconds,
        'dataPoints': sessionData.length,
        'emotionCategory': emotionCategory,
        'emotionIcon': _emotionIcons[emotionCategory] ?? '😐',
        'confidence': _calculateConfidence(sessionData),
      },
      'vadStats': vadStats,
      'emotionPattern': emotionPattern,
      'cbtFeedback': cbtFeedback,
      'recommendations': recommendations,
      'charts': _generateChartData(sessionData),
    };
  }

  /// VAD 통계 계산
  static Map<String, dynamic> _calculateVADStats(List<EmotionDataPoint> data) {
    if (data.isEmpty) return {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0};

    double totalValence = 0.0;
    double totalArousal = 0.0;
    double totalDominance = 0.0;

    for (final point in data) {
      totalValence += point.valence;
      totalArousal += point.arousal;
      totalDominance += point.dominance;
    }

    final count = data.length.toDouble();
    
    return {
      'valence': totalValence / count,
      'arousal': totalArousal / count,
      'dominance': totalDominance / count,
      'valenceTrend': _calculateTrend(data.map((e) => e.valence).toList()),
      'arousalTrend': _calculateTrend(data.map((e) => e.arousal).toList()),
      'dominanceTrend': _calculateTrend(data.map((e) => e.dominance).toList()),
    };
  }

  /// 감정 카테고리 결정
  static String _determineEmotionCategory(Map<String, dynamic> vadStats) {
    final valence = vadStats['valence'] as double;
    final arousal = vadStats['arousal'] as double;
    final dominance = vadStats['dominance'] as double;

    // VAD 값을 기반으로 감정 카테고리 결정
    if (valence > 0.6 && arousal > 0.4) return 'joy';
    if (valence < -0.3 && arousal < 0.2) return 'sadness';
    if (valence < -0.4 && arousal > 0.5) return 'anger';
    if (valence < -0.2 && arousal > 0.6) return 'fear';
    if (arousal > 0.7) return 'surprise';
    if (valence < -0.5) return 'disgust';
    if (valence > 0.4 && arousal < 0.3) return 'calm';
    if (arousal > 0.5 && dominance < 0.3) return 'anxiety';
    if (valence > 0.5 && arousal > 0.5) return 'excitement';
    
    return 'neutral';
  }

  /// 감정 변화 패턴 분석
  static Map<String, dynamic> _analyzeEmotionPattern(List<EmotionDataPoint> data) {
    if (data.length < 2) {
      return {
        'stability': 'stable',
        'volatility': 'low',
        'trend': 'neutral',
        'keyMoments': [],
      };
    }

    final valenceTrend = _calculateTrend(data.map((e) => e.valence).toList());
    final arousalTrend = _calculateTrend(data.map((e) => e.arousal).toList());
    
    // 안정성 분석
    final stability = _analyzeStability(data);
    
    // 변동성 분석
    final volatility = _analyzeVolatility(data);
    
    // 전반적 트렌드
    final trend = _analyzeOverallTrend(valenceTrend, arousalTrend);
    
    // 주요 순간들
    final keyMoments = _findKeyMoments(data);

    return {
      'stability': stability,
      'volatility': volatility,
      'trend': trend,
      'keyMoments': keyMoments,
      'valenceTrend': valenceTrend,
      'arousalTrend': arousalTrend,
    };
  }

  /// CBT 피드백 생성
  static Map<String, dynamic> _generateCBTFeedback(Map<String, dynamic> vadStats, Map<String, dynamic> pattern) {
    final valence = vadStats['valence'] as double;
    final arousal = vadStats['arousal'] as double;
    final stability = pattern['stability'] as String;
    final trend = pattern['trend'] as String;

    List<String> techniques = [];
    String mainAdvice = '';
    String explanation = '';

    // 감정 상태에 따른 CBT 기법 추천
    if (valence < -0.3) {
      techniques.add('인지 재구성 (Cognitive Restructuring)');
      techniques.add('감정 일기 작성');
      mainAdvice = '현재 부정적인 감정 상태를 인식하고, 이를 객관적으로 바라보는 연습을 해보세요.';
      explanation = '부정적인 감정이 지속될 때는 그 감정의 근본 원인을 찾아 인지적 왜곡을 교정하는 것이 도움이 됩니다.';
    } else if (arousal > 0.6) {
      techniques.add('호흡 조절 (Breathing Exercise)');
      techniques.add('점진적 근육 이완법');
      mainAdvice = '현재 높은 활성화 상태입니다. 깊은 호흡과 함께 긴장을 풀어보세요.';
      explanation = '높은 활성화 상태는 스트레스나 불안을 나타낼 수 있습니다. 이완 기법을 통해 안정을 찾을 수 있습니다.';
    } else if (stability == 'unstable') {
      techniques.add('마음챙김 명상 (Mindfulness)');
      techniques.add('감정 라벨링');
      mainAdvice = '감정이 자주 변하는 상태입니다. 현재 순간에 집중하는 연습을 해보세요.';
      explanation = '감정의 불안정성은 외부 자극에 과도하게 반응하고 있음을 의미합니다. 마음챙김을 통해 안정감을 찾을 수 있습니다.';
    } else {
      techniques.add('감사 연습 (Gratitude Practice)');
      techniques.add('긍정적 재해석');
      mainAdvice = '전반적으로 안정적인 감정 상태입니다. 이 상태를 유지하고 발전시켜보세요.';
      explanation = '안정적이고 긍정적인 감정 상태는 정신 건강에 매우 좋습니다. 이러한 상태를 더욱 강화해보세요.';
    }

    return {
      'mainAdvice': mainAdvice,
      'explanation': explanation,
      'techniques': techniques,
      'dailyPractice': _generateDailyPractice(techniques),
      'emergencyTips': _generateEmergencyTips(valence, arousal),
    };
  }

  /// 개선 제안 생성
  static List<Map<String, dynamic>> _generateRecommendations(Map<String, dynamic> vadStats, Map<String, dynamic> pattern) {
    final recommendations = <Map<String, dynamic>>[];
    
    final valence = vadStats['valence'] as double;
    final arousal = vadStats['arousal'] as double;
    final stability = pattern['stability'] as String;

    if (valence < -0.3) {
      recommendations.add({
        'title': '긍정적 활동 증가',
        'description': '일상에서 작은 즐거움을 찾아보세요. 취미 활동이나 친구와의 만남을 늘려보세요.',
        'priority': 'high',
        'icon': '😊',
      });
    }

    if (arousal > 0.6) {
      recommendations.add({
        'title': '스트레스 관리',
        'description': '정기적인 운동, 명상, 충분한 휴식을 통해 스트레스를 관리해보세요.',
        'priority': 'high',
        'icon': '🧘',
      });
    }

    if (stability == 'unstable') {
      recommendations.add({
        'title': '일상의 규칙성',
        'description': '규칙적인 생활 패턴을 만들어 감정의 안정성을 높여보세요.',
        'priority': 'medium',
        'icon': '📅',
      });
    }

    recommendations.add({
      'title': '정기적인 감정 체크',
      'description': '매일 짧은 시간이라도 자신의 감정 상태를 점검해보세요.',
      'priority': 'low',
      'icon': '📊',
    });

    return recommendations;
  }

  /// 차트 데이터 생성
  static Map<String, dynamic> _generateChartData(List<EmotionDataPoint> data) {
    if (data.isEmpty) return {};

    final timeLabels = <String>[];
    final valenceData = <double>[];
    final arousalData = <double>[];
    final dominanceData = <double>[];

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      timeLabels.add('${i + 1}');
      valenceData.add(point.valence);
      arousalData.add(point.arousal);
      dominanceData.add(point.dominance);
    }

    return {
      'timeLabels': timeLabels,
      'valenceData': valenceData,
      'arousalData': arousalData,
      'dominanceData': dominanceData,
    };
  }

  // 헬퍼 메서드들
  static double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    double sum = 0.0;
    for (int i = 1; i < values.length; i++) {
      sum += values[i] - values[i - 1];
    }
    return sum / (values.length - 1);
  }

  static String _analyzeStability(List<EmotionDataPoint> data) {
    if (data.length < 3) return 'stable';
    
    double variance = 0.0;
    final mean = data.map((e) => e.valence).reduce((a, b) => a + b) / data.length;
    
    for (final point in data) {
      variance += pow(point.valence - mean, 2);
    }
    variance /= data.length;
    
    return variance > 0.1 ? 'unstable' : 'stable';
  }

  static String _analyzeVolatility(List<EmotionDataPoint> data) {
    if (data.length < 2) return 'low';
    
    double totalChange = 0.0;
    for (int i = 1; i < data.length; i++) {
      totalChange += (data[i].valence - data[i - 1].valence).abs();
    }
    
    final avgChange = totalChange / (data.length - 1);
    if (avgChange > 0.3) return 'high';
    if (avgChange > 0.1) return 'medium';
    return 'low';
  }

  static String _analyzeOverallTrend(double valenceTrend, double arousalTrend) {
    if (valenceTrend > 0.1 && arousalTrend < 0.1) return 'improving';
    if (valenceTrend < -0.1 && arousalTrend > 0.1) return 'worsening';
    return 'stable';
  }

  static List<Map<String, dynamic>> _findKeyMoments(List<EmotionDataPoint> data) {
    if (data.length < 3) return [];
    
    final moments = <Map<String, dynamic>>[];
    
    for (int i = 1; i < data.length - 1; i++) {
      final prev = data[i - 1];
      final current = data[i];
      final next = data[i + 1];
      
      final valenceChange = (current.valence - prev.valence).abs();
      final arousalChange = (current.arousal - prev.arousal).abs();
      
      if (valenceChange > 0.3 || arousalChange > 0.3) {
        moments.add({
          'index': i,
          'timestamp': current.timestamp.toIso8601String(),
          'type': valenceChange > arousalChange ? 'emotion_shift' : 'energy_shift',
          'description': _describeMoment(current, prev),
        });
      }
    }
    
    return moments;
  }

  static String _describeMoment(EmotionDataPoint current, EmotionDataPoint prev) {
    final valenceDiff = current.valence - prev.valence;
    final arousalDiff = current.arousal - prev.arousal;
    
    if (valenceDiff > 0.3) return '긍정적 감정 상승';
    if (valenceDiff < -0.3) return '부정적 감정 상승';
    if (arousalDiff > 0.3) return '활성화 증가';
    if (arousalDiff < -0.3) return '활성화 감소';
    
    return '감정 변화';
  }

  static Duration _calculateSessionDuration(List<EmotionDataPoint> data) {
    if (data.length < 2) return Duration.zero;
    
    final start = data.first.timestamp;
    final end = data.last.timestamp;
    return end.difference(start);
  }

  static double _calculateConfidence(List<EmotionDataPoint> data) {
    if (data.isEmpty) return 0.0;
    
    // 데이터 포인트 수와 일관성을 기반으로 신뢰도 계산
    final baseConfidence = (data.length / 10.0).clamp(0.0, 1.0);
    final consistency = _analyzeStability(data) == 'stable' ? 0.2 : 0.0;
    
    return (baseConfidence + consistency).clamp(0.0, 1.0);
  }

  static List<String> _generateDailyPractice(List<String> techniques) {
    return [
      '매일 10분 명상하기',
      '감정 일기 작성하기',
      '깊은 호흡 연습하기',
      '감사하는 일 3가지 적기',
    ];
  }

  static List<String> _generateEmergencyTips(double valence, double arousal) {
    final tips = <String>[];
    
    if (valence < -0.5) {
      tips.add('5-4-3-2-1 감각 체크하기');
      tips.add('따뜻한 차 한 잔 마시기');
    }
    
    if (arousal > 0.7) {
      tips.add('4-7-8 호흡법 시도하기');
      tips.add('차가운 물로 손 씻기');
    }
    
    tips.add('신뢰할 수 있는 사람에게 연락하기');
    tips.add('잠시 산책하기');
    
    return tips;
  }

  static Map<String, dynamic> _generateEmptyAnalysis() {
    return {
      'analysis': {
        'timestamp': DateTime.now().toIso8601String(),
        'sessionDuration': Duration.zero.inSeconds,
        'dataPoints': 0,
        'emotionCategory': 'neutral',
        'emotionIcon': '😐',
        'confidence': 0.0,
      },
      'vadStats': {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0},
      'emotionPattern': {
        'stability': 'stable',
        'volatility': 'low',
        'trend': 'neutral',
        'keyMoments': [],
      },
      'cbtFeedback': {
        'mainAdvice': '데이터가 충분하지 않습니다. 더 긴 대화를 시도해보세요.',
        'explanation': '분석을 위해서는 최소 3개 이상의 데이터 포인트가 필요합니다.',
        'techniques': ['감정 일기 작성', '정기적인 체크인'],
        'dailyPractice': ['매일 감정 상태 기록하기'],
        'emergencyTips': ['신뢰할 수 있는 사람에게 연락하기'],
      },
      'recommendations': [
        {
          'title': '더 긴 대화 시도',
          'description': '분석을 위해 최소 1-2분 정도의 대화를 시도해보세요.',
          'priority': 'high',
          'icon': '💬',
        }
      ],
      'charts': {},
    };
  }
} 