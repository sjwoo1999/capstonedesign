import 'package:flutter/material.dart';
import '../../theme/bemore_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('분석 기록'),
        backgroundColor: BeMoreTheme.surfaceColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감정 분석 기록',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '이전 분석 결과들을 확인해보세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BeMoreTheme.textSecondary,
                ),
                ),
              const SizedBox(height: 24),
              Expanded(
                child: _buildHistoryList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    // 임시 데이터
    final historyItems = [
      {
        'date': '2024.01.15',
        'time': '14:30',
        'emotion': '기쁨',
        'valence': 0.8,
        'arousal': 0.6,
        'dominance': 0.7,
      },
      {
        'date': '2024.01.14',
        'time': '09:15',
        'emotion': '평온',
        'valence': 0.6,
        'arousal': 0.3,
        'dominance': 0.5,
      },
      {
        'date': '2024.01.13',
        'time': '18:45',
        'emotion': '불안',
        'valence': 0.3,
        'arousal': 0.7,
        'dominance': 0.4,
      },
    ];

    if (historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: BeMoreTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 분석 기록이 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: BeMoreTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 감정 분석을 시작해보세요!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeMoreTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        final item = historyItems[index];
        final emotionColor = BeMoreTheme.emotionColors[item['emotion']] ?? BeMoreTheme.textSecondary;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // 감정 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: emotionColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getEmotionIcon(item['emotion'].toString()),
                    color: emotionColor,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item['emotion'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: emotionColor,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${item['date']} ${item['time']}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BeMoreTheme.textSecondary,
            ),
          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildVADIndicator('V', (item['valence'] as num).toDouble(), BeMoreTheme.successColor),
                          const SizedBox(width: 8),
                          _buildVADIndicator('A', (item['arousal'] as num).toDouble(), BeMoreTheme.warningColor),
                          const SizedBox(width: 8),
                          _buildVADIndicator('D', (item['dominance'] as num).toDouble(), BeMoreTheme.primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 화살표
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: BeMoreTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVADIndicator(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(value * 100).toInt()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
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
