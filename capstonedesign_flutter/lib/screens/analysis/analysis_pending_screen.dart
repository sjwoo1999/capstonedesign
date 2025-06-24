import 'package:flutter/material.dart';
import '../../services/mock_analysis_service.dart';
import '../../models/emotion_data_point.dart';
import '../home/home_screen.dart';
import 'analysis_result_screen.dart';

class AnalysisPendingScreen extends StatefulWidget {
  final List<EmotionDataPoint> sessionData;
  
  const AnalysisPendingScreen({
    super.key,
    required this.sessionData,
  });

  @override
  State<AnalysisPendingScreen> createState() => _AnalysisPendingScreenState();
}

class _AnalysisPendingScreenState extends State<AnalysisPendingScreen> {
  bool _isAnalyzing = true;
  String _statusMessage = '분석을 시작합니다...';

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  void _performAnalysis() async {
    // 즉시 분석 수행
    setState(() {
      _statusMessage = 'VAD 데이터 분석 중...';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusMessage = '감정 패턴 분석 중...';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusMessage = 'CBT 피드백 생성 중...';
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusMessage = '분석 완료!';
    });
    
    await Future.delayed(const Duration(milliseconds: 300));
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // 어두운 배경색
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(
                  Icons.science_outlined,
                  size: 80,
                  color: Color(0xFF6366F1), // 포인트 색상
                ),
                const SizedBox(height: 24),
                const Text(
                  '대화 분석이 시작되었습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    // HomeScreen으로 이동하면서 이전의 모든 라우트를 제거합니다.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('홈으로 돌아가기', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 