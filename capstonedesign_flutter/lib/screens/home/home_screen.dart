// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../session/session_screen.dart';
import '../chat/chat_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              _buildHeader(context),
              
              const SizedBox(height: 32),
              
              // 오늘의 감정 상태
              _buildTodayEmotion(context),
              
              const SizedBox(height: 24),
              
              // 빠른 시작 카드
              _buildQuickStartCard(context),
              
              const SizedBox(height: 24),
              
              // AI 대화 카드
              _buildAIChatCard(context),
              
              const SizedBox(height: 24),
              
              // 최근 피드백
              _buildRecentFeedback(context),
              
              const SizedBox(height: 24),
              
              // 통계 카드
              _buildStatsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: BeMoreTheme.textPrimary,
            fontWeight: FontWeight.bold,
              ),
          ),
            Text(
              '오늘도 BeMore와 함께 감정을 인식해보세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BeMoreTheme.textSecondary,
        ),
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: BeMoreTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayEmotion(BuildContext context) {
    return Consumer<VADProvider>(
      builder: (context, vadProvider, child) {
        final stats = vadProvider.getEmotionStats();
        final dominantEmotion = stats['dominantEmotion'] as String;
        final emotionColor = BeMoreTheme.emotionColors[dominantEmotion] ?? BeMoreTheme.textSecondary;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: emotionColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '오늘의 감정 상태',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: emotionColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getEmotionIcon(dominantEmotion),
                        color: emotionColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                          Text(
                            dominantEmotion,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: emotionColor,
                            ),
                          ),
                          Text(
                            '${stats['emotionCount']}개의 감정 데이터 수집됨',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BeMoreTheme.textSecondary,
                            ),
            ),
                        ],
          ),
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

  Widget _buildQuickStartCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SessionScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BeMoreTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: BeMoreTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '새로운 상담 시작',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '멀티모달 감정 분석을 시작하세요',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BeMoreTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('표정 분석', Icons.face),
                  _buildFeatureChip('음성 분석', Icons.mic),
                  _buildFeatureChip('텍스트 분석', Icons.text_fields),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIChatCard(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BeMoreTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: BeMoreTheme.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI와 대화하기',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '음성으로 AI와 자연스럽게 대화하세요',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BeMoreTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('AI 응답', Icons.smart_toy, BeMoreTheme.accentColor),
                  _buildFeatureChip('실시간 대화', Icons.chat, BeMoreTheme.accentColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, [Color? color]) {
    final chipColor = color ?? BeMoreTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFeedback(BuildContext context) {
    return Consumer<CBTProvider>(
      builder: (context, cbtProvider, child) {
        final recentFeedbacks = cbtProvider.getRecentFeedbacks(3);
        
        if (recentFeedbacks.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '최근 피드백',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 48,
                          color: BeMoreTheme.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '아직 피드백이 없습니다',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BeMoreTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '첫 번째 상담을 시작해보세요!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BeMoreTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 피드백',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...recentFeedbacks.map((feedback) => _buildFeedbackCard(context, feedback)),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(BuildContext context, dynamic feedback) {
    final emotionColor = BeMoreTheme.emotionColors[feedback.emotionCategory] ?? BeMoreTheme.textSecondary;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: emotionColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmotionIcon(feedback.emotionCategory),
                color: emotionColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feedback.emotionCategory,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: emotionColor,
                    ),
                  ),
                  Text(
                    feedback.cognitiveDistortion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: BeMoreTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: BeMoreTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
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
                  '이번 주 통계',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(context, '분석 횟수', '${stats['emotionCount']}', Icons.analytics, BeMoreTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(context, '주요 감정', stats['dominantEmotion'], Icons.psychology, BeMoreTheme.secondaryColor),
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

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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
