// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import '../record/record_screen.dart'; // ✅ RecordScreen 연결

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigateToRecord(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        centerTitle: true,
      ),
      body: orientation == Orientation.portrait
          ? _buildPortraitLayout(context)
          : _buildLandscapeLayout(context),
    );
  }

  Widget _buildPortraitLayout(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '오늘의 감정을 분석해볼까요?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToRecord(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('분석 시작하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mood, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                const Text(
                  '마음 상태를\n한눈에 분석해드립니다.',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '카메라를 보며 감정을 기록하고\n분석된 결과를 확인하세요.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _navigateToRecord(context),
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text('분석 시작하기', style: TextStyle(fontSize: 20)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '🙌 분석 영상은 저장되지 않습니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
