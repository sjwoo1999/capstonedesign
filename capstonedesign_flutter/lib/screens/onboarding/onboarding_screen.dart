import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../theme/bemore_theme.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'BeMore와 함께\n감정을 인식하세요',
      subtitle: '얼굴 표정, 음성 톤, 텍스트를 종합 분석하여\n당신의 감정을 정확하게 파악합니다',
      image: 'assets/animations/emotion_recognition.json',
      color: BeMoreTheme.primaryColor,
    ),
    OnboardingPage(
      title: 'VAD 기반\n감정 분석',
      subtitle: 'Valence(긍정성), Arousal(활성화), Dominance(지배성)\n세 가지 차원으로 감정을 수치화합니다',
      image: 'assets/animations/vad_analysis.json',
      color: BeMoreTheme.secondaryColor,
    ),
    OnboardingPage(
      title: 'CBT 기반\n맞춤 피드백',
      subtitle: '인지행동치료 기법을 바탕으로\n당신에게 최적화된 피드백을 제공합니다',
      image: 'assets/animations/cbt_feedback.json',
      color: BeMoreTheme.accentColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    // 온보딩 완료 상태 저장
    Provider.of<EmotionProvider>(context, listen: false).setOnboardingCompleted(true);
    
    // 홈 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 페이지 인디케이터
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 건너뛰기 버튼
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      '건너뛰기',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BeMoreTheme.textSecondary,
                      ),
                    ),
                  ),
                  
                  // 페이지 인디케이터
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _pages[index].color
                              : BeMoreTheme.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 이전 버튼
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        '이전',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: BeMoreTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  // 다음/시작 버튼
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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
}

class OnboardingPage {
  final String title;
  final String subtitle;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 애니메이션 이미지 (임시로 아이콘 사용)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForPage(page),
              size: 80,
              color: page.color,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // 제목
          Text(
            page.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: BeMoreTheme.textPrimary,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // 부제목
          Text(
            page.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: BeMoreTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(OnboardingPage page) {
    if (page.title.contains('감정을 인식')) {
      return Icons.psychology;
    } else if (page.title.contains('VAD')) {
      return Icons.analytics;
    } else if (page.title.contains('CBT')) {
      return Icons.lightbulb;
    }
    return Icons.favorite;
  }
} 