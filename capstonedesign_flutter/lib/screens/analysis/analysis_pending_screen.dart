import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class AnalysisPendingScreen extends StatelessWidget {
  const AnalysisPendingScreen({super.key});

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
                  '대화 내용에 대한 심층 분석이 진행 중입니다.\n분석이 완료되면 푸시 알림으로 알려드릴게요.\n\n앱을 종료하셔도 괜찮습니다.',
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