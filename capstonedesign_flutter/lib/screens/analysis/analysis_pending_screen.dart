import 'package:flutter/material.dart';
import '../../services/mock_analysis_service.dart';
import '../../models/emotion_data_point.dart';
import '../home/home_screen.dart';
import 'analysis_result_screen.dart';
import 'dart:math' as math;

class AnalysisPendingScreen extends StatefulWidget {
  final List<EmotionDataPoint> sessionData;
  
  const AnalysisPendingScreen({
    super.key,
    required this.sessionData,
  });

  @override
  State<AnalysisPendingScreen> createState() => _AnalysisPendingScreenState();
}

class _AnalysisPendingScreenState extends State<AnalysisPendingScreen>
    with TickerProviderStateMixin {
  bool _isAnalyzing = true;
  String _statusMessage = '분석을 시작합니다...';
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _sparkleController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _performAnalysis();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
    _sparkleController.repeat();
    _glowController.repeat(reverse: true);
  }

  void _performAnalysis() async {
    // 즉시 분석 수행
    if (mounted) {
      setState(() {
        _statusMessage = 'VAD 데이터 분석 중... ✨';
      });
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _statusMessage = '감정 패턴 분석 중... 🌟';
      });
    }
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _statusMessage = 'CBT 피드백 생성 중... 💫';
      });
    }
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _statusMessage = '분석 완료! 🎉';
      });
    }
    
    await Future.delayed(const Duration(seconds: 2));
    
    // 분석 결과 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalysisResultScreen(
            sessionData: widget.sessionData,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _sparkleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                
                // 스파클 효과 배경
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 배경 스파클들
                    ...List.generate(8, (index) => _buildSparkle(index)),
                    
                    // 메인 아이콘과 애니메이션
                    AnimatedBuilder(
                      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFf8f9ff)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(_glowAnimation.value * 0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: AnimatedBuilder(
                              animation: _rotateAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateAnimation.value * 2 * math.pi,
                                  child: const Icon(
                                    Icons.psychology,
                                    size: 60,
                                    color: Color(0xFF667eea),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // 제목
                const Text(
                  'AI가 당신의 감정을\n분석하고 있어요 ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    letterSpacing: -0.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 부제목
                Text(
                  '마법 같은 AI가 당신의 마음을 읽고 있어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 상태 메시지
                AnimatedBuilder(
                  animation: _sparkleAnimation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(_sparkleAnimation.value * 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _sparkleAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(_sparkleAnimation.value),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _statusMessage,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // 진행 바
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Stack(
                    children: [
                      LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      // 진행 바 위의 반짝이는 효과
                      AnimatedBuilder(
                        animation: _sparkleAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: _sparkleAnimation.value * MediaQuery.of(context).size.width * 0.8,
                            top: 0,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(_sparkleAnimation.value),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 진행 상태 텍스트
                AnimatedBuilder(
                  animation: _sparkleAnimation,
                  builder: (context, child) {
                    return Text(
                      'AI가 당신의 마음을 읽는 중...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7 + _sparkleAnimation.value * 0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // 홈으로 돌아가기 버튼
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFf8f9ff)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                          
                        );
                      },
                      child: const Center(
                        child: Text(
                          '홈으로 돌아가기',
                          style: TextStyle(
                            color: Color(0xFF667eea),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSparkle(int index) {
    return AnimatedBuilder(
      animation: _sparkleController,
      builder: (context, child) {
        final angle = (index * 45) * (math.pi / 180);
        final radius = 80.0;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        
        return Positioned(
          left: 60 + x,
          top: 60 + y,
          child: Transform.rotate(
            angle: _sparkleController.value * 2 * math.pi,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(_sparkleAnimation.value * 0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 