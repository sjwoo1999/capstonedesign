// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import '../../theme/bemore_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoSaveEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: BeMoreTheme.surfaceColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '앱 설정',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BeMore 앱을 더 편리하게 사용하세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BeMoreTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // 일반 설정
              _buildSectionTitle('일반'),
              _buildSettingsCard([
                _buildSwitchTile(
                  '알림',
                  '분석 완료 및 피드백 알림을 받습니다',
                  Icons.notifications,
                  _notificationsEnabled,
                  (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  '자동 저장',
                  '분석 결과를 자동으로 저장합니다',
                  Icons.save,
                  _autoSaveEnabled,
                  (value) {
                    setState(() {
                      _autoSaveEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  '다크 모드',
                  '어두운 테마를 사용합니다',
                  Icons.dark_mode,
                  _darkModeEnabled,
                  (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                  },
                ),
              ]),
              
              const SizedBox(height: 24),
              
              // 분석 설정
              _buildSectionTitle('분석 설정'),
              _buildSettingsCard([
                _buildListTile(
                  '분석 모드',
                  '멀티모달 (표정+음성+텍스트)',
                  Icons.analytics,
                  () {
                    _showAnalysisModeDialog();
                  },
                ),
                _buildListTile(
                  '분석 시간',
                  '30초',
                  Icons.timer,
                  () {
                    _showAnalysisTimeDialog();
                  },
                ),
              ]),
              
              const SizedBox(height: 24),
              
              // 데이터 관리
              _buildSectionTitle('데이터 관리'),
              _buildSettingsCard([
                _buildListTile(
                  '데이터 내보내기',
                  '분석 결과를 PDF로 저장',
                  Icons.download,
                  () {
                    _exportData();
                  },
                ),
                _buildListTile(
                  '데이터 삭제',
                  '모든 분석 기록 삭제',
                  Icons.delete_forever,
                  () {
                    _showDeleteConfirmDialog();
                  },
                ),
              ]),
              
              const SizedBox(height: 24),
              
              // 앱 정보
              _buildSectionTitle('앱 정보'),
              _buildSettingsCard([
                _buildListTile(
                  '버전',
                  '1.0.0',
                  Icons.info,
                  null,
                ),
                _buildListTile(
                  '개발자',
                  '우성종',
                  Icons.person,
                  null,
                ),
                _buildListTile(
                  '라이선스',
                  'MIT License',
                  Icons.description,
                  () {
                    _showLicenseDialog();
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: BeMoreTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BeMoreTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: BeMoreTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: BeMoreTheme.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: BeMoreTheme.primaryColor,
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: BeMoreTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: BeMoreTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: BeMoreTheme.textSecondary,
        ),
      ),
      trailing: onTap != null
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: BeMoreTheme.textSecondary,
            )
          : null,
      onTap: onTap,
    );
  }

  void _showAnalysisModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분석 모드 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('멀티모달'),
              subtitle: const Text('표정 + 음성 + 텍스트'),
              value: 'multimodal',
              groupValue: 'multimodal',
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('표정만'),
              subtitle: const Text('얼굴 표정 분석'),
              value: 'facial',
              groupValue: 'multimodal',
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('음성만'),
              subtitle: const Text('음성 톤 분석'),
              value: 'voice',
              groupValue: 'multimodal',
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('분석 시간 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('15초'),
              value: 15,
              groupValue: 30,
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('30초'),
              value: 30,
              groupValue: 30,
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<int>(
              title: const Text('60초'),
              value: 60,
              groupValue: 30,
              onChanged: (value) {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('데이터 내보내기 기능은 준비 중입니다.'),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 삭제'),
        content: const Text('모든 분석 기록이 영구적으로 삭제됩니다.\n정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('모든 데이터가 삭제되었습니다.'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: BeMoreTheme.errorColor,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('라이선스'),
        content: const Text(
          'BeMore 앱은 MIT 라이선스 하에 배포됩니다.\n\n'
          'Copyright (c) 2024 우성종\n\n'
          'Permission is hereby granted, free of charge, to any person obtaining a copy '
          'of this software and associated documentation files (the "Software"), to deal '
          'in the Software without restriction, including without limitation the rights '
          'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '
          'copies of the Software, and to permit persons to whom the Software is '
          'furnished to do so, subject to the following conditions...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
