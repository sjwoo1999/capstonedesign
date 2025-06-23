import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../home/home_screen.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

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
        child: SingleChildScrollView(
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
    return Consumer<VADProvider>(
      builder: (context, vadProvider, child) {
        final currentEmotion = vadProvider.currentEmotion;
        if (currentEmotion == null) return const SizedBox.shrink();

        final emotionColor = BeMoreTheme.emotionColors[currentEmotion.emotionCategory] ?? BeMoreTheme.textSecondary;

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
                  child: Icon(
                    _getEmotionIcon(currentEmotion.emotionCategory),
                    size: 40,
                    color: emotionColor,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 감정 카테고리
                Text(
                  currentEmotion.emotionCategory,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: emotionColor,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 분석 시간
                Text(
                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} 분석 완료',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BeMoreTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVADChart(BuildContext context) {
    return Consumer<VADProvider>(
      builder: (context, vadProvider, child) {
        final currentEmotion = vadProvider.currentEmotion;
        if (currentEmotion == null) return const SizedBox.shrink();

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
                _buildVADBar(context, 'Valence (긍정성)', currentEmotion.valence, BeMoreTheme.successColor),
                const SizedBox(height: 12),
                _buildVADBar(context, 'Arousal (활성화)', currentEmotion.arousal, BeMoreTheme.warningColor),
                const SizedBox(height: 12),
                _buildVADBar(context, 'Dominance (지배성)', currentEmotion.dominance, BeMoreTheme.primaryColor),
              ],
            ),
          ),
        );
      },
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
            widthFactor: value,
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
    return Consumer<VADProvider>(
      builder: (context, vadProvider, child) {
        final stats = vadProvider.getEmotionStats();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '멀티모달 분석 결과',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildAnalysisItem(context, '얼굴 표정', '${vadProvider.facialEmotions.length}개', Icons.face, BeMoreTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalysisItem(context, '음성 톤', '${vadProvider.voiceEmotions.length}개', Icons.mic, BeMoreTheme.secondaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAnalysisItem(context, '텍스트', '${vadProvider.textEmotions.length}개', Icons.text_fields, BeMoreTheme.accentColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BeMoreTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCBTFeedback(BuildContext context) {
    return Consumer<CBTProvider>(
      builder: (context, cbtProvider, child) {
        final feedback = cbtProvider.currentFeedback;
        if (feedback == null) return const SizedBox.shrink();

        final emotionColor = BeMoreTheme.emotionColors[feedback.emotionCategory] ?? BeMoreTheme.textSecondary;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: emotionColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CBT 맞춤 피드백',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 인지 왜곡
                _buildFeedbackSection(
                  context,
                  '인지 왜곡',
                  feedback.cognitiveDistortion,
                  Icons.psychology,
                  BeMoreTheme.warningColor,
                ),
                
                const SizedBox(height: 16),
                
                // 도전 과제
                _buildFeedbackSection(
                  context,
                  '도전 과제',
                  feedback.challenge,
                  Icons.flag,
                  BeMoreTheme.primaryColor,
                ),
                
                const SizedBox(height: 16),
                
                // 인지 재구성
                _buildFeedbackSection(
                  context,
                  '인지 재구성',
                  feedback.reframe,
                  Icons.refresh,
                  BeMoreTheme.successColor,
                ),
                
                const SizedBox(height: 16),
                
                // 행동 계획
                _buildFeedbackSection(
                  context,
                  '행동 계획',
                  feedback.actionPlan,
                  Icons.directions_run,
                  BeMoreTheme.accentColor,
                ),
                
                const SizedBox(height: 16),
                
                // CBT 기법들
                Text(
                  '추천 CBT 기법',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: feedback.techniques.map((technique) => 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: emotionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        technique,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: emotionColor,
                        ),
                      ),
                    ),
                  ).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedbackSection(BuildContext context, String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title,
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
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
          ),
        ),
      ],
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
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

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case '기쁨':
        return Icons.sentiment_very_satisfied;
      case '평온':
        return Icons.sentiment_satisfied;
      case '슬픔':
        return Icons.sentiment_dissatisfied;
      case '불안':
        return Icons.sentiment_very_dissatisfied;
      case '분노':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
} 