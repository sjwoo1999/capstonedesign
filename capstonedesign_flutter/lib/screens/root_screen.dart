// lib/screens/root_screen.dart
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'social/social_screen.dart';
import 'history/history_screen.dart'; // 기록 화면으로 변경
import 'settings/settings_screen.dart';
import '../theme/bemore_theme.dart'; // BeMore 테마 사용

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
    HistoryScreen(), // 기록 화면으로 변경
    SettingsScreen(),
  ];

  final List<String> _titles = const [
    '홈',
    '소셜',
    '기록', // 기록으로 변경
    '설정',
  ];

  final List<IconData> _icons = const [
    Icons.home,
    Icons.people_alt,
    Icons.history, // 기록 아이콘으로 변경
    Icons.settings,
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
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: BeMoreTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: BeMoreTheme.primaryColor,
        unselectedItemColor: BeMoreTheme.textSecondary,
        backgroundColor: BeMoreTheme.surfaceColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: List.generate(_titles.length, (index) {
          return BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          );
        }),
      ),
    );
  }
}
