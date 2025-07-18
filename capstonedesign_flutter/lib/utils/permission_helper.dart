import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      print('🔍 카메라 권한 상태 확인');
      final status = await Permission.camera.status;
      print('📱 현재 카메라 권한 상태: $status');
      
      if (status.isGranted) {
        print('✅ 카메라 권한 이미 허용됨');
        return true;
      }
      
      // 권한이 없으면 사용자에게 설명 후 요청
      if (status.isDenied) {
        print('📱 카메라 권한이 거부됨, 사용자에게 설명 후 권한 요청');
        
        // 강화된 권한 요청 다이얼로그
        final shouldRequest = await _showCameraPermissionDialog(context);
        
        if (!shouldRequest) {
          print('❌ 사용자가 카메라 권한 요청을 취소함');
          return false;
        }
        
        // 권한 요청 전에 잠시 대기
        await Future.delayed(const Duration(seconds: 1));
        
        // iOS에서 권한 요청이 작동하지 않을 수 있으므로 여러 번 시도
        PermissionStatus result = PermissionStatus.denied;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (result.isDenied && retryCount < maxRetries) {
          print('📱 카메라 권한 요청 시도 ${retryCount + 1}/$maxRetries');
          
          // 직접 권한 요청
          result = await Permission.camera.request();
          print('📱 카메라 권한 요청 결과: $result');
          
          if (result.isGranted) {
            print('✅ 카메라 권한 허용됨');
            return true;
          }
          
          if (result.isDenied && retryCount < maxRetries - 1) {
            print('⚠️ 카메라 권한 요청 실패, 잠시 후 재시도');
            await Future.delayed(const Duration(seconds: 2));
          }
          
          retryCount++;
        }
        
        // 모든 시도 후에도 권한이 거부된 경우
        if (!result.isGranted) {
          print('❌ 카메라 권한 요청 실패, 설정으로 이동 안내');
          await _showCameraSettingsDialog(context);
        }
        
        return result.isGranted;
      } 
      
      // 영구 거부된 경우
      if (status.isPermanentlyDenied) {
        print('🚫 카메라 권한 영구 거부됨, 설정으로 이동 안내');
        await _showCameraSettingsDialog(context);
        return false;
      }
      
      return false;
      
    } catch (e) {
      print('❌ 카메라 권한 확인 중 오류: $e');
      return false;
    }
  }

  // 카메라 권한 요청 다이얼로그
  static Future<bool> _showCameraPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '카메라 권한이 필요해요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BeMore이 더 정확한 감정 분석을 위해 카메라 접근이 필요합니다.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '카메라로 할 수 있는 것들:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('😊 실시간 표정 분석'),
                    _buildFeatureItem('📊 정확한 감정 상태 추적'),
                    _buildFeatureItem('🎯 개인화된 CBT 피드백'),
                    _buildFeatureItem('📈 감정 변화 패턴 분석'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '개인정보는 안전하게 보호되며, 서버로 전송되지 않습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                '나중에',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '권한 허용',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  static Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // 카메라 설정 다이얼로그
  static Future<void> _showCameraSettingsDialog(BuildContext context) async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '설정에서 권한을 허용해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '카메라 권한이 거부되었습니다.\n설정에서 권한을 허용해주세요:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_iphone, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '설정 방법:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSettingStep('1', '설정 앱 열기'),
                    _buildSettingStep('2', 'BeMore 앱 찾기'),
                    _buildSettingStep('3', '권한 탭 선택'),
                    _buildSettingStep('4', '카메라 권한 허용'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '권한을 허용한 후 앱으로 돌아와서 다시 시도해주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '설정으로 이동',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (shouldOpenSettings) {
      await openAppSettings();
    }
  }

  static Widget _buildSettingStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  static Future<bool> requestMicrophonePermission(BuildContext context) async {
    try {
      print('🎤 마이크 권한 상태 확인');
      final status = await Permission.microphone.status;
      print('📱 현재 마이크 권한 상태: $status');
      
      if (status.isGranted) {
        print('✅ 마이크 권한 이미 허용됨');
        return true;
      }
      
      // 권한이 없으면 사용자에게 설명 후 요청
      if (status.isDenied) {
        print('📱 마이크 권한이 거부됨, 사용자에게 설명 후 권한 요청');
        
        // 강화된 권한 요청 다이얼로그
        final shouldRequest = await _showMicrophonePermissionDialog(context);
        
        if (!shouldRequest) {
          print('❌ 사용자가 마이크 권한 요청을 취소함');
          return false;
        }
        
        // 권한 요청 전에 잠시 대기
        await Future.delayed(const Duration(seconds: 1));
        
        // 직접 권한 요청
        final result = await Permission.microphone.request();
        print('📱 마이크 권한 요청 결과: $result');
        
        if (result.isGranted) {
          return true;
        }
        
        // 권한이 여전히 거부된 경우 설정 안내
        if (!result.isGranted) {
          print('❌ 마이크 권한이 여전히 거부됨, 설정으로 이동 안내');
          await _showMicrophoneSettingsDialog(context);
        }
        
        return false;
      } 
      
      // 영구 거부된 경우
      if (status.isPermanentlyDenied) {
        print('🚫 마이크 권한 영구 거부됨, 설정으로 이동 안내');
        await _showMicrophoneSettingsDialog(context);
        return false;
      }
      
      return false;
      
    } catch (e) {
      print('❌ 마이크 권한 확인 중 오류: $e');
      return false;
    }
  }

  // 마이크 권한 요청 다이얼로그
  static Future<bool> _showMicrophonePermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  '마이크 권한이 필요해요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BeMore이 더 정확한 감정 분석을 위해 마이크 접근이 필요합니다.',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '마이크로 할 수 있는 것들:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('🎤 실시간 음성 분석'),
                    _buildFeatureItem('📊 정확한 감정 상태 추적'),
                    _buildFeatureItem('🎯 개인화된 CBT 피드백'),
                    _buildFeatureItem('📈 감정 변화 패턴 분석'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '개인정보는 안전하게 보호되며, 서버로 전송되지 않습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                '나중에',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '권한 허용',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // 마이크 설정 다이얼로그
  static Future<void> _showMicrophoneSettingsDialog(BuildContext context) async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '설정에서 권한을 허용해주세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '마이크 권한이 거부되었습니다.\n설정에서 권한을 허용해주세요:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_iphone, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '설정 방법:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSettingStep('1', '설정 앱 열기'),
                    _buildSettingStep('2', 'BeMore 앱 찾기'),
                    _buildSettingStep('3', '권한 탭 선택'),
                    _buildSettingStep('4', '마이크 권한 허용'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '권한을 허용한 후 앱으로 돌아와서 다시 시도해주세요.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '설정으로 이동',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (shouldOpenSettings) {
      await openAppSettings();
    }
  }
} 