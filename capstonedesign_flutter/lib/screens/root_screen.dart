// lib/screens/root_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'social/social_screen.dart';
import 'report/report_history_screen.dart'; // ✅
import 'settings/settings_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SocialScreen(),
    ReportHistoryScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    '홈',
    '소셜',
    '리포트',
    '설정',
  ];

  final List<List<Widget>> _actions = const [
    [], // 홈 탭은 액션 없음
    [], // 소셜 탭도 없음
    [], // 리포트 탭도 없음
    [IconButton(onPressed: null, icon: Icon(Icons.settings))], // 설정 탭 예시
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: _actions[_selectedIndex],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: '소셜'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
