// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text(
          '설정 화면 준비 중...',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
