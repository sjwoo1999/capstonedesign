import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../../services/emotion_api_services.dart';
import '../../models/emotion_data_point.dart';
import '../home/home_screen.dart';
import 'dart:convert';

class AnalysisResultScreen extends StatefulWidget {
  final List<EmotionDataPoint> sessionData;
  
  const AnalysisResultScreen({
    super.key,
    required this.sessionData,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  Map<String, dynamic>? _analysisResult;
  bool _isLoading = true;
  final EmotionAPIService _apiService = EmotionAPIService();

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() async {
    try {
      // 실제 API 서비스를 사용하여 분석 수행
      final result = await _performRealAnalysis();
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
      
      print('📊 분석 완료: ${jsonEncode(result)}');
    } catch (e) {
      print('❌ 분석 실패: $e');
      // 실패 시 Mock 데이터 사용
      final mockResult = _generateMockResult();
      setState(() {
        _analysisResult = mockResult;
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _performRealAnalysis() async {
    // 세션 데이터에서 다양한 모달리티 데이터 추출
    String textData = _extractTextFromSession();
    String? imageData = _extractImageFromSession();
    String? audioData = _extractAudioFromSession();
    
    Map<String, dynamic> apiResult;
    
    // 멀티모달 분석 수행
    if (imageData != null && audioData != null) {
      // 이미지 + 음성 멀티모달 분석
      apiResult = await _apiService.sendMultimodalAnalysis(imageData, audioData);
    } else if (imageData != null) {
      // 이미지만 분석
      apiResult = await _apiService.sendImageForAnalysis(imageData);
    } else if (audioData != null) {
      // 음성만 분석
      apiResult = await _apiService.sendAudioForAnalysis(audioData);
    } else {
      // 텍스트만 분석
      apiResult = await _apiService.sendTextForAnalysis(textData);
    }
    
    // API 응답을 Flutter 앱 형식으로 변환
    return _convertApiResponseToAppFormat(apiResult);
  }

  String _extractTextFromSession() {
    // 세션 데이터에서 텍스트 정보 추출
    // 실제 구현에서는 사용자 입력 텍스트나 음성 전사 텍스트 사용
    return "오늘 하루 감정 분석을 위한 텍스트 데이터";
  }

  String? _extractImageFromSession() {
    // 세션 데이터에서 이미지 정보 추출
    // 실제 구현에서는 캡처된 얼굴 이미지 사용
    return null; // 현재는 null 반환
  }

  String? _extractAudioFromSession() {
    // 세션 데이터에서 오디오 정보 추출
    // 실제 구현에서는 녹음된 음성 데이터 사용
    return null; // 현재는 null 반환
  }

  Map<String, dynamic> _convertApiResponseToAppFormat(Map<String, dynamic> apiResult) {
    // 서버 API 응답을 Flutter 앱 형식으로 변환
    final vadScore = apiResult['final_vad'] ?? apiResult['text_vad'] ?? {
      'valence': 0.5,
      'arousal': 0.5,
      'dominance': 0.5
    };
    
    final emotionTag = apiResult['emotion_tag'] ?? 'neutral';
    
    return {
      'analysis': {
        'timestamp': DateTime.now().toIso8601String(),
        'sessionDuration': _calculateSessionDuration(widget.sessionData).inSeconds,
        'dataPoints': widget.sessionData.length,
        'emotionCategory': _mapEmotionTagToCategory(emotionTag),
        'emotionIcon': _getEmotionEmoji(emotionTag),
        'confidence': 0.85, // API에서 제공하는 경우 사용
      },
      'vadStats': {
        'valence': vadScore['valence'] ?? 0.5,
        'arousal': vadScore['arousal'] ?? 0.5,
        'dominance': vadScore['dominance'] ?? 0.5,
        'valenceTrend': 'stable',
        'arousalTrend': 'stable',
        'dominanceTrend': 'stable',
      },
      'emotionPattern': {
        'stability': 'stable',
        'volatility': 'low',
        'trend': 'neutral',
        'keyMoments': [],
      },
      'cbtFeedback': _generateCBTFeedbackFromAPI(apiResult),
      'recommendations': _generateRecommendationsFromAPI(apiResult),
      'charts': _generateChartData(widget.sessionData),
    };
  }

  String _mapEmotionTagToCategory(String emotionTag) {
    final mapping = {
      'happy': 'joy',
      'sad': 'sadness',
      'angry': 'anger',
      'fear': 'fear',
      'surprise': 'surprise',
      'disgust': 'disgust',
      'neutral': 'neutral',
      'anxious': 'anxiety',
      'calm': 'calm',
      'excited': 'excitement',
    };
    return mapping[emotionTag] ?? 'neutral';
  }

  String _getEmotionEmoji(String emotionTag) {
    final iconMapping = {
      'happy': '😄',
      'sad': '😢',
      'angry': '😠',
      'fear': '😨',
      'surprise': '😲',
      'disgust': '🤢',
      'neutral': '😐',
      'anxious': '😰',
      'calm': '😌',
      'excited': '😃',
    };
    return iconMapping[emotionTag] ?? '😐';
  }

  Map<String, dynamic> _generateCBTFeedbackFromAPI(Map<String, dynamic> apiResult) {
    final cbtStrategy = apiResult['cbt_strategy'] ?? {};
    final gptResponse = apiResult['gpt_response'] ?? '';
    
    return {
      'mainAdvice': cbtStrategy['name'] ?? '감정 관리 전략',
      'explanation': gptResponse.isNotEmpty ? gptResponse : '현재 감정 상태를 바탕으로 한 맞춤형 조언입니다.',
      'techniques': cbtStrategy['techniques'] ?? ['감정 인식하기', '호흡 조절하기'],
      'dailyPractice': cbtStrategy['exercises'] ?? ['감정 일기 작성', '명상 연습'],
      'emergencyTips': ['깊은 호흡하기', '5-4-3-2-1 감각 인식하기', '긍정적 자기 대화하기'],
    };
  }

  List<Map<String, dynamic>> _generateRecommendationsFromAPI(Map<String, dynamic> apiResult) {
    final cbtStrategy = apiResult['cbt_strategy'] ?? {};
    final exercises = cbtStrategy['exercises'] ?? [];
    
    return exercises.map<Map<String, dynamic>>((exercise) => {
      'title': exercise,
      'description': '이 활동을 통해 감정 관리 능력을 향상시킬 수 있습니다.',
      'icon': '🧠',
      'difficulty': 'easy',
    }).toList();
  }

  Duration _calculateSessionDuration(List<EmotionDataPoint> data) {
    if (data.isEmpty) return Duration.zero;
    return data.last.timestamp.difference(data.first.timestamp);
  }

  Map<String, dynamic> _generateChartData(List<EmotionDataPoint> data) {
    // 차트 데이터 생성 로직
    return {
      'vadChart': data.map((point) => {
        'timestamp': point.timestamp.millisecondsSinceEpoch,
        'valence': point.valence,
        'arousal': point.arousal,
        'dominance': point.dominance,
      }).toList(),
    };
  }

  Map<String, dynamic> _generateMockResult() {
    // Mock 데이터 생성 (API 실패 시 사용)
    return {
      'analysis': {
        'timestamp': DateTime.now().toIso8601String(),
        'sessionDuration': _calculateSessionDuration(widget.sessionData).inSeconds,
        'dataPoints': widget.sessionData.length,
        'emotionCategory': 'neutral',
        'emotionIcon': '😐',
        'confidence': 0.75,
      },
      'vadStats': {
        'valence': 0.5,
        'arousal': 0.5,
        'dominance': 0.5,
        'valenceTrend': 'stable',
        'arousalTrend': 'stable',
        'dominanceTrend': 'stable',
      },
      'emotionPattern': {
        'stability': 'stable',
        'volatility': 'low',
        'trend': 'neutral',
        'keyMoments': [],
      },
      'cbtFeedback': {
        'mainAdvice': '현재 안정적인 감정 상태입니다.',
        'explanation': '감정이 안정적으로 유지되고 있습니다.',
        'techniques': ['감정 인식하기', '호흡 조절하기'],
        'dailyPractice': ['감정 일기 작성', '명상 연습'],
        'emergencyTips': ['깊은 호흡하기', '5-4-3-2-1 감각 인식하기'],
      },
      'recommendations': [
        {
          'title': '감정 일기 작성',
          'description': '매일 감정을 기록하여 패턴을 파악해보세요.',
          'icon': '📝',
          'difficulty': 'easy',
        }
      ],
      'charts': _generateChartData(widget.sessionData),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('분석 결과'),
        backgroundColor: BeMoreTheme.surfaceColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('분석 중...', style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 결과 헤더
                  _buildResultHeader(context),
                  
                  const SizedBox(height: 24),
                  
                  // VAD 차트
                  _buildVADChart(context),
                  
                  const SizedBox(height: 24),
                  
                  // 감정 분석 결과
                  _buildEmotionAnalysis(context),
                  
                  const SizedBox(height: 24),
                  
                  // CBT 피드백
                  _buildCBTFeedback(context),
                  
                  const SizedBox(height: 24),
                  
                  // 개선 제안
                  _buildRecommendations(context),
                  
                  const SizedBox(height: 32),
                  
                  // 액션 버튼
                  _buildActionButtons(context),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final analysis = _analysisResult!['analysis'] as Map<String, dynamic>;
    final emotionCategory = analysis['emotionCategory'] as String;
    final emotionIcon = analysis['emotionIcon'] as String? ?? '😐';
    final confidence = analysis['confidence'] as double;
    final dataPoints = analysis['dataPoints'] as int;
    
    final emotionColor = BeMoreTheme.emotionColors[emotionCategory] ?? BeMoreTheme.textSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 감정 아이콘
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: emotionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emotionIcon,
                  style: TextStyle(
                    fontSize: 40,
                    color: emotionColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 감정 카테고리
            Text(
              _getEmotionDisplayName(emotionCategory),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: emotionColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 분석 정보
            Text(
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} 분석 완료',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeMoreTheme.textSecondary,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // 신뢰도 및 데이터 포인트
            Text(
              '신뢰도: ${(confidence * 100).toInt()}% | 데이터: ${dataPoints}개',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: BeMoreTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVADChart(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final vadStats = _analysisResult!['vadStats'] as Map<String, dynamic>;
    final valence = vadStats['valence'] as double;
    final arousal = vadStats['arousal'] as double;
    final dominance = vadStats['dominance'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VAD 감정 분석',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // VAD 바 차트
            _buildVADBar(context, 'Valence (긍정성)', valence, BeMoreTheme.successColor),
            const SizedBox(height: 12),
            _buildVADBar(context, 'Arousal (활성화)', arousal, BeMoreTheme.warningColor),
            const SizedBox(height: 12),
            _buildVADBar(context, 'Dominance (지배성)', dominance, BeMoreTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildVADBar(BuildContext context, String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: ((value + 1) / 2).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionAnalysis(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final emotionPattern = _analysisResult!['emotionPattern'] as Map<String, dynamic>;
    final stability = emotionPattern['stability'] as String;
    final volatility = emotionPattern['volatility'] as String;
    final trend = emotionPattern['trend'] as String;
    final keyMoments = emotionPattern['keyMoments'] as List<dynamic>;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '감정 변화 패턴',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 패턴 정보
            _buildPatternInfo(context, '안정성', stability, _getStabilityColor(stability)),
            const SizedBox(height: 12),
            _buildPatternInfo(context, '변동성', volatility, _getVolatilityColor(volatility)),
            const SizedBox(height: 12),
            _buildPatternInfo(context, '전체 트렌드', trend, _getTrendColor(trend)),
            
            if (keyMoments.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '주요 순간들',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...keyMoments.take(3).map((moment) => _buildKeyMoment(context, moment)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternInfo(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMoment(BuildContext context, dynamic moment) {
    final description = moment['description'] as String;
    final type = moment['type'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeMoreTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeMoreTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            type == 'emotion_shift' ? Icons.psychology : Icons.trending_up,
            size: 16,
            color: BeMoreTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCBTFeedback(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final cbtFeedback = _analysisResult!['cbtFeedback'] as Map<String, dynamic>;
    final mainAdvice = cbtFeedback['mainAdvice'] as String;
    final explanation = cbtFeedback['explanation'] as String;
    final techniques = cbtFeedback['techniques'] as List<dynamic>;
    final dailyPractice = cbtFeedback['dailyPractice'] as List<dynamic>;
    final emergencyTips = cbtFeedback['emergencyTips'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CBT 피드백',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 주요 조언
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BeMoreTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BeMoreTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 주요 조언',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: BeMoreTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mainAdvice,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 설명
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeMoreTheme.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CBT 기법
            Text(
              '추천 CBT 기법',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...techniques.map((technique) => _buildTechniqueItem(context, technique)),
            
            const SizedBox(height: 16),
            
            // 일상 연습
            Text(
              '일상 연습',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...dailyPractice.map((practice) => _buildPracticeItem(context, practice)),
            
            const SizedBox(height: 16),
            
            // 긴급 팁
            Text(
              '긴급 상황 대처법',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...emergencyTips.map((tip) => _buildEmergencyTip(context, tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildTechniqueItem(BuildContext context, String technique) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeMoreTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeMoreTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: BeMoreTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              technique,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItem(BuildContext context, String practice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeMoreTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeMoreTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 16,
            color: BeMoreTheme.successColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              practice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTip(BuildContext context, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BeMoreTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BeMoreTheme.warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emergency,
            size: 16,
            color: BeMoreTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final recommendations = _analysisResult!['recommendations'] as List<dynamic>?;
    
    if (recommendations == null || recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '개선 제안',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...recommendations.map((rec) => _buildRecommendationItem(context, rec as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, Map<String, dynamic> recommendation) {
    final title = recommendation['title'] as String? ?? '제목 없음';
    final description = recommendation['description'] as String? ?? '설명 없음';
    final priority = recommendation['priority'] as String? ?? 'low';
    final icon = recommendation['icon'] as String? ?? '💡';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = BeMoreTheme.errorColor;
        break;
      case 'medium':
        priorityColor = BeMoreTheme.warningColor;
        break;
      default:
        priorityColor = BeMoreTheme.successColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority == 'high' ? '높음' : priority == 'medium' ? '보통' : '낮음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // 홈으로 돌아가기
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BeMoreTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              '홈으로 돌아가기',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 새로운 상담 시작
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              '새로운 상담 시작',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getEmotionDisplayName(String emotion) {
    switch (emotion) {
      case '기쁨':
        return '기쁨';
      case '평온':
        return '평온';
      case '슬픔':
        return '슬픔';
      case '불안':
        return '불안';
      case '분노':
        return '분노';
      default:
        return '기쁨';
    }
  }

  Color _getStabilityColor(String stability) {
    switch (stability) {
      case 'stable':
        return BeMoreTheme.successColor;
      case 'unstable':
        return BeMoreTheme.warningColor;
      default:
        return BeMoreTheme.textSecondary;
    }
  }

  Color _getVolatilityColor(String volatility) {
    switch (volatility) {
      case 'low':
        return BeMoreTheme.successColor;
      case 'medium':
        return BeMoreTheme.warningColor;
      case 'high':
        return BeMoreTheme.errorColor;
      default:
        return BeMoreTheme.textSecondary;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'improving':
        return BeMoreTheme.successColor;
      case 'worsening':
        return BeMoreTheme.errorColor;
      case 'stable':
        return BeMoreTheme.primaryColor;
      default:
        return BeMoreTheme.textSecondary;
    }
  }
} 