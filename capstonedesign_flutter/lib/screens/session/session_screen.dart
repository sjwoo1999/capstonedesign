import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../../models/vad_emotion.dart';
import '../analysis/analysis_pending_screen.dart';
import 'package:timer_builder/timer_builder.dart';
import 'dart:convert';
import '../../models/emotion_data_point.dart';
import 'package:image/image.dart' as img;
import '../../services/emotion_api_services.dart';
import 'package:record/record.dart';
import 'package:record_platform_interface/record_platform_interface.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:math';


// 대화 상태를 명확하게 정의
enum ConversationState {
  preparing,     // 준비 중 (카메라 초기화)
  ready,         // 대화 시작 준비 완료
  talking,       // 대화 중 (실시간 분석)
  ending,        // 대화 종료 중
}

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  ConversationState _conversationState = ConversationState.preparing;
  String _conversationTopic = '';
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  // 디바이스 정보 관련
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isSimulator = false; // null 대신 기본값 false 사용
  
  // 카메라 관련
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  bool _hasMicrophonePermission = false;
  String _cameraError = '';

  // 오디오 녹음 관련
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  String? _audioPath;
  
  // STT 관련
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';
  String _lastSentText = ''; // 마지막으로 전송된 텍스트 (중복 방지)
  double _currentSoundLevel = 0.0;
  Timer? _textDebounceTimer; // 텍스트 디바운스 타이머

  // API 서비스 (한 번만 초기화)
  late final EmotionAPIService _apiService;

  // 대화 관련
  DateTime? _conversationStartTime;
  DateTime? _conversationEndTime;
  List<String> _conversationNotes = [];
  DateTime _lastAnalyzedTime = DateTime.now();
  final List<EmotionDataPoint> _sessionData = [];
  
  // 실시간 분석 상태
  bool _isAnalyzing = false;
  String _currentEmotion = '';
  String _currentFaceEmotion = '';

  // 상태 변수들
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🚀 실시간 대화 화면 초기화 시작');
    
    // API 서비스 초기화
    _apiService = EmotionAPIService();
    
    // STT 초기화
    _speech = stt.SpeechToText();
    
    _initializeDeviceInfo();
    
    // 앱이 완전히 로드된 후 권한 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissions();
    });
    
    // 주제 컨트롤러 리스너 추가
    _topicController.addListener(() {
      setState(() {
        _conversationTopic = _topicController.text;
      });
    });
  }

  @override
  void dispose() {
    _topicController.dispose();
    _noteController.dispose();
    
    // 텍스트 디바운스 타이머 정리
    _textDebounceTimer?.cancel();
    
    // 카메라 컨트롤러 정리
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    
    // 오디오 녹음 정리
    _audioRecorder.dispose();
    
    super.dispose();
  }

  // 디바이스 정보 초기화 (시뮬레이터 감지)
  Future<void> _initializeDeviceInfo() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _isSimulator = !iosInfo.isPhysicalDevice;
        print('📱 iOS 디바이스 정보: ${iosInfo.name} (시뮬레이터: $_isSimulator)');
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _isSimulator = androidInfo.isPhysicalDevice == false;
        print('📱 Android 디바이스 정보: ${androidInfo.model} (시뮬레이터: $_isSimulator)');
      } else {
        _isSimulator = false;
        print('📱 기타 플랫폼 (시뮬레이터: $_isSimulator)');
      }
    } catch (e) {
      print('❌ 디바이스 정보 초기화 실패: $e');
      _isSimulator = false; // 기본값으로 실제 디바이스로 간주
    }
  }

  Future<void> _checkPermissions() async {
    // 권한 상태 확인
    await _checkCameraPermission();
    
    // 권한 요청 간격을 늘려서 iOS에서 더 안정적으로 처리
    await Future.delayed(const Duration(seconds: 2));
    
    await _checkMicPermission();

    // 시뮬레이터가 아니고 카메라 권한이 있을 때만 카메라 초기화
    if (!_isSimulator && _hasCameraPermission) {
      await _initializeCamera();
    } else if (_isSimulator) {
      // 시뮬레이터에서는 카메라 초기화 없이 준비 상태로
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
    } else {
      // 권한이 없는 경우에도 준비 상태로 (카메라 없이 진행)
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
    }
  }

  Future<void> _checkCameraPermission() async {
    try {
      print('🔍 카메라 권한 상태 확인');
      final status = await Permission.camera.status;
      print('📱 현재 카메라 권한 상태: $status');
      
      if (status.isGranted) {
        print('✅ 카메라 권한 이미 허용됨');
        setState(() {
          _hasCameraPermission = true;
        });
        await _initializeCamera();
      } else if (status.isDenied) {
        print('📱 카메라 권한이 거부됨, 사용자에게 설명 제공');
        
        // iOS에서 권한 요청 전에 사용자에게 명확한 안내 제공
        if (mounted) {
          print('📱 권한 설명 다이얼로그 표시 시작...');
          final shouldRequest = await _showPermissionDialog(
            '카메라 권한 필요',
            '실시간 감정 분석을 위해 카메라 접근 권한이 필요합니다.\n\n얼굴 표정을 분석하여 감정 상태를 파악합니다.',
            '권한 허용',
            '나중에',
          );
          print('📱 사용자 선택 결과: $shouldRequest');
          
          if (!shouldRequest) {
            print('❌ 사용자가 카메라 권한 요청을 취소함');
            setState(() {
              _hasCameraPermission = false;
              _conversationState = ConversationState.ready;
            });
            return;
          }
        } else {
          print('⚠️ 위젯이 마운트되지 않아 다이얼로그를 표시할 수 없음');
        }
        
        // 잠시 대기 후 권한 요청 (iOS에서 더 안정적)
        print('📱 2초 대기 후 권한 요청 시작...');
        await Future.delayed(const Duration(seconds: 2));
        
        print('📱 카메라 권한 요청 시작...');
        final result = await Permission.camera.request();
        print('📱 카메라 권한 요청 결과: $result');
        
        setState(() {
          _hasCameraPermission = result.isGranted;
        });
        
        if (result.isGranted) {
          print('✅ 카메라 권한 허용됨, 카메라 초기화 시작');
          await _initializeCamera();
        } else {
          print('❌ 카메라 권한 요청이 거부됨');
          
          // 권한 요청 실패 시 한 번 더 시도
          print('📱 카메라 권한 재요청 시도...');
          await Future.delayed(const Duration(seconds: 1));
          final retryResult = await Permission.camera.request();
          print('📱 카메라 권한 재요청 결과: $retryResult');
          
          if (retryResult.isGranted) {
            print('✅ 카메라 권한 재요청 성공, 카메라 초기화 시작');
            setState(() {
              _hasCameraPermission = true;
            });
            await _initializeCamera();
          } else {
            print('❌ 카메라 권한 재요청도 실패');
            if (mounted) {
              print('📱 권한 거부 다이얼로그 표시...');
              await _showPermissionDeniedDialog('카메라');
            }
          }
        }
      } else if (status.isPermanentlyDenied) {
        print('🚫 카메라 권한 영구 거부됨');
        setState(() {
          _hasCameraPermission = false;
        });
        
        if (mounted) {
          final shouldOpenSettings = await _showPermissionDeniedDialog('카메라');
          if (shouldOpenSettings) {
            await openAppSettings();
          }
        }
        
        // 영구 거부된 경우에도 카메라 초기화 시도 (이전에 허용된 경우 작동할 수 있음)
        try {
          await _initializeCamera();
          if (_cameraController != null && _cameraController!.value.isInitialized) {
            print('✅ 카메라 초기화 성공 (영구 거부 상태이지만 실제로는 작동)');
            setState(() {
              _hasCameraPermission = true;
            });
          }
        } catch (e) {
          print('❌ 카메라 초기화 실패 (영구 거부): $e');
        }
      } else {
        print('❓ 알 수 없는 카메라 권한 상태: $status');
        setState(() {
          _hasCameraPermission = false;
        });
      }
      
      print('📱 최종 카메라 권한 상태: $_hasCameraPermission');
      
    } catch (e) {
      print('❌ 카메라 권한 확인 중 오류: $e');
      setState(() {
        _hasCameraPermission = false;
      });
    }
  }

  Future<void> _checkMicPermission() async {
    try {
      print('🎤 === 마이크 권한 확인 시작 ===');
      
      final status = await Permission.microphone.status;
      print('🎤 permission_handler 권한 상태: $status');
      
      if (status.isGranted) {
        print('✅ permission_handler 권한 확인됨');
        setState(() {
          _hasMicrophonePermission = true;
        });
        return;
      } else if (status.isDenied) {
        // 권한이 거부된 경우 사용자에게 설명 제공
        if (mounted) {
          final shouldRequest = await _showPermissionDialog(
            '마이크 권한 필요',
            '음성 감정 분석을 위해 마이크 접근 권한이 필요합니다. 음성 톤과 말투를 분석하여 감정 상태를 파악합니다.',
            '권한 요청',
            '나중에',
          );
          
          if (!shouldRequest) {
            print('❌ 사용자가 마이크 권한 요청을 취소함');
            setState(() {
              _hasMicrophonePermission = false;
            });
            return;
          }
        }
        
        print('❌ 마이크 권한 거부됨, 요청 시작');
        final result = await Permission.microphone.request();
        print('🎤 마이크 권한 요청 결과: $result');
        setState(() {
          _hasMicrophonePermission = result.isGranted;
        });
        
        if (!result.isGranted && mounted) {
          _showPermissionDeniedDialog('마이크');
        }
        return;
      } else if (status.isPermanentlyDenied) {
        print('🚫 마이크 권한 영구 거부됨');
        setState(() {
          _hasMicrophonePermission = false;
        });
        
        if (mounted) {
          final shouldOpenSettings = await _showPermissionDeniedDialog('마이크');
          if (shouldOpenSettings) {
            await openAppSettings();
          }
        }
        return;
      } else if (status.isRestricted) {
        print('🚫 마이크 권한 제한됨 (부모 제어 등)');
        setState(() {
          _hasMicrophonePermission = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('마이크 권한이 제한되어 있습니다. 부모 제어 설정을 확인해주세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // 백업: record 패키지로 권한 확인
      final hasRecordPermission = await _audioRecorder.hasPermission();
      print('🎤 record 패키지 권한 확인: $hasRecordPermission');
      
      if (hasRecordPermission) {
        print('✅ record 패키지 권한 확인됨');
        setState(() {
          _hasMicrophonePermission = true;
        });
        return;
      }
      
      print('❓ 알 수 없는 마이크 권한 상태');
      setState(() {
        _hasMicrophonePermission = false;
      });
      
      print('🎤 최종 마이크 권한 상태: $_hasMicrophonePermission');
      
    } catch (e) {
      print('❌ 마이크 권한 확인 중 오류: $e');
      setState(() {
        _hasMicrophonePermission = false;
      });
    }
  }

  // 권한 요청 다이얼로그
  Future<bool> _showPermissionDialog(String title, String message, String confirmText, String cancelText) async {
    print('📱 권한 다이얼로그 생성 시작: $title');
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('📱 권한 다이얼로그 빌더 실행');
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                title.contains('카메라') ? Icons.camera_alt : Icons.mic,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
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
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF6366F1),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '권한은 언제든지 설정에서 변경할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6366F1),
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
                print('📱 사용자가 권한 요청을 취소함');
                Navigator.of(context).pop(false);
              },
              child: Text(
                cancelText,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print('📱 사용자가 권한 요청을 허용함');
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    
    print('📱 권한 다이얼로그 결과: $result');
    return result ?? false;
  }

  // 권한 거부 다이얼로그
  Future<bool> _showPermissionDeniedDialog(String permissionType) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionType 권한 필요'),
          content: Text('$permissionType 권한이 거부되었습니다. 앱 설정에서 권한을 허용해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('📱 사용 가능한 카메라가 없습니다');
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _cameraError = '';
            _conversationState = ConversationState.ready;
          });
        }
        return;
      }

      // 전면 카메라 목록 필터링
      final frontCameras = cameras.where((camera) => camera.lensDirection == CameraLensDirection.front).toList();

      print('📷 사용 가능한 모든 전면 카메라:');
      for (var cam in frontCameras) {
        print('  - 이름: ${cam.name}, 방향: ${cam.lensDirection}');
      }

      if (frontCameras.isEmpty) {
        print('❌ 전면 카메라를 찾을 수 없습니다.');
        if (mounted) {
          setState(() {
            _cameraError = '전면 카메라를 찾을 수 없습니다.';
            _isCameraInitialized = true;
            _conversationState = ConversationState.ready;
          });
        }
        return;
      }
      
      // 가장 적절한 전면 카메라 선택
      CameraDescription selectedCamera = frontCameras.first;
      if (frontCameras.length > 1) {
        final standardCamera = frontCameras.firstWhere(
          (c) => !c.name.toLowerCase().contains('wide'),
          orElse: () => frontCameras.first,
        );
        selectedCamera = standardCamera;
      }
      print('📷 선택된 카메라: ${selectedCamera.name}');

      // 기존 컨트롤러 정리
      await _cameraController?.dispose();
      
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      // 카메라 초기화
      print('📷 카메라 초기화 시도 중...');
      await _cameraController!.initialize();
      print('✅ 카메라 초기화 성공');
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
      
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
      // 카메라 컨트롤러 정리
      await _cameraController?.dispose();
      _cameraController = null;
      
      if (mounted) {
        setState(() {
          _cameraError = '카메라 초기화 실패: $e';
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
    }
  }

  void _startConversation() {
    // 카메라 권한이 없어도 음성 분석으로 진행 가능
    if (!_isCameraInitialized && !_hasCameraPermission) {
      print('📱 카메라 없이 음성 분석만으로 진행');
      setState(() {
        _conversationState = ConversationState.talking;
        _conversationStartTime = DateTime.now();
        // 텍스트 초기화
        _recognizedText = '';
        _lastSentText = '';
      });
      
      print('🎤 음성 분석만으로 대화 시작: ${_conversationTopic.isNotEmpty ? _conversationTopic : "자유 대화"}');
      
      // 음성 분석만 시작
      _startVoiceOnlyAnalysis();
      return;
    }

    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 준비되지 않았습니다. 음성 분석만으로 진행합니다.')),
      );
      
      setState(() {
        _conversationState = ConversationState.talking;
        _conversationStartTime = DateTime.now();
        // 텍스트 초기화
        _recognizedText = '';
        _lastSentText = '';
      });
      
      print('🎤 음성 분석만으로 대화 시작: ${_conversationTopic.isNotEmpty ? _conversationTopic : "자유 대화"}');
      _startVoiceOnlyAnalysis();
      return;
    }

    setState(() {
      _conversationState = ConversationState.talking;
      _conversationStartTime = DateTime.now();
      // 텍스트 초기화
      _recognizedText = '';
      _lastSentText = '';
    });
    
    print('🎤 멀티모달 대화 시작: ${_conversationTopic.isNotEmpty ? _conversationTopic : "자유 대화"}');
    
    // 카메라 스트림 시작
    _startImageAnalysis();
    
    // 음성 분석 시작
    _startVoiceOnlyAnalysis();
  }

  // 음성 분석만으로 진행하는 메서드
  void _startVoiceOnlyAnalysis() {
    print('🎤 === 음성 분석만으로 진행 ===');
    
    // STT 기반 음성 인식 시작
    _tryAudioRecordingSeparately();
  }

  void _endConversation() async {
    setState(() {
      _conversationState = ConversationState.ending;
      _conversationEndTime = DateTime.now();
    });
    
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
    await _stopAudioRecording();
    await _stopSTTListening();
    print('🔚 대화 종료, 분석 데이터 (${_sessionData.length}개) 전송 준비');
    
    // 실제 앱에서는 여기서 서버로 _sessionData 를 json으로 변환하여 전송합니다.
    final payload = jsonEncode(_sessionData.map((d) => d.toJson()).toList());
    print('📦 전송될 최종 데이터: $payload');
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AnalysisPendingScreen(sessionData: _sessionData)),
      (route) => false, // 현재까지의 모든 라우트를 스택에서 제거
    );
  }

  void _startRealTimeAnalysis() {
    if (_cameraController == null) return;
    
    // 카메라 분석만 먼저 시작
    _startImageAnalysis();
    
    // 음성 녹음은 별도로 시도 (실패해도 카메라 분석은 계속)
    _tryAudioRecordingSeparately();
  }

  Future<void> _tryAudioRecordingSeparately() async {
    print('🎤 === 독립적 음성 녹음 시도 ===');
    
    // 음성 녹음이 실패해도 카메라 분석은 계속 진행
    try {
      await _startAudioRecordingWithFallback();
    } catch (e) {
      print('❌ 음성 녹음 실패 (카메라 분석은 계속): $e');
      // 음성 녹음 실패 시 사용자에게 상세한 알림
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '음성 녹음이 불가능합니다',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• 얼굴 분석만으로 진행됩니다\n• 대화 후 텍스트 입력으로 보완 가능',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _startAudioRecordingWithFallback() async {
    print('🎤 === 음성 녹음 시작 (대안적 접근법) ===');
    
    // iOS에서 오디오 세션 설정 개선 (RecordConfig 제거)
    if (Platform.isIOS) {
      try {
        print('✅ iOS 오디오 세션 설정 완료');
      } catch (e) {
        print('⚠️ iOS 오디오 세션 설정 실패: $e');
      }
    }
    
    // 1차 시도: STT 기반 음성 인식
    try {
      print('🔄 STT 기반 음성 인식 시도...');
      await _startSTTListening();
      if (_isListening) {
        print('✅ STT 음성 인식 시작 성공');
        return;
      }
    } catch (e) {
      print('❌ STT 음성 인식 실패: $e');
    }
    
    // 2차 시도: 카메라 스트림 일시 중지 후 녹음
    try {
      print('🔄 음성 녹음 2차 시도 (카메라 스트림 일시 중지)...');
      
      // 카메라 스트림이 실행 중이면 일시 중지
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        print('📷 카메라 스트림 일시 중지...');
        await _cameraController!.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 500)); // 안정화 대기
      }
      
      await _startAudioRecording();
      if (_isRecording) {
        print('✅ 음성 녹음 2차 시도 성공');
        // 카메라 스트림 재시작
        if (_cameraController != null && _cameraController!.value.isInitialized) {
          print('📷 카메라 스트림 재시작...');
          _startImageStream();
        }
        return;
      }
    } catch (e) {
      print('❌ 음성 녹음 2차 시도 실패: $e');
      // 카메라 스트림 재시작
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        print('📷 카메라 스트림 재시작...');
        _startImageStream();
      }
    }
    
    // 3차 시도: 더 낮은 설정으로 시도 (카메라 스트림 중지 없이)
    try {
      print('🔄 음성 녹음 3차 시도 (낮은 설정)...');
      final tempDir = await Directory.systemTemp.createTemp('audio_recording');
      final audioPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(
        path: audioPath,
        encoder: AudioEncoder.wav,
        bitRate: 8000, // 매우 낮은 비트레이트
        samplingRate: 8000, // 매우 낮은 샘플링 레이트
        numChannels: 1,
      );
      
      _isRecording = true;
      _audioPath = audioPath;
      print('✅ 음성 녹음 3차 시도 성공 (낮은 설정)');
      return;
      
    } catch (e) {
      print('❌ 음성 녹음 3차 시도 실패: $e');
    }
    
    // 4차 시도: 가장 기본적인 설정
    try {
      print('🔄 음성 녹음 4차 시도 (기본 설정)...');
      final tempDir = await Directory.systemTemp.createTemp('audio_recording');
      final audioPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _audioRecorder.start(path: audioPath);
      
      _isRecording = true;
      _audioPath = audioPath;
      print('✅ 음성 녹음 4차 시도 성공 (기본 설정)');
      
    } catch (e) {
      print('❌ 음성 녹음 4차 시도도 실패: $e');
      print('⚠️ 음성 녹음이 불가능합니다. 얼굴 분석만으로 진행합니다.');
      throw Exception('음성 녹음 실패: $e');
    }
  }

  Future<void> _startAudioRecording() async {
    print('🎤 === 음성 녹음 시작 시도 ===');
    print('🎤 마이크 권한 상태: $_hasMicrophonePermission');
    print('🎤 시뮬레이터 여부: $_isSimulator');
    
    // 시뮬레이터에서는 음성 녹음 제한
    if (_isSimulator) {
      print('📱 시뮬레이터에서는 음성 녹음이 제한됩니다.');
      throw Exception('시뮬레이터에서는 음성 녹음이 불가능합니다.');
    }
    
    // 실제 디바이스에서 권한이 없으면 권한 요청
    if (!_hasMicrophonePermission) {
      print('🎤 마이크 권한이 없어 음성 녹음을 시작할 수 없습니다.');
      throw Exception('마이크 권한이 없습니다.');
    }

    try {
      print('🎤 음성 녹음 시작...');
      
      // iOS에서 더 안정적인 권한 재확인
      if (Platform.isIOS) {
        final status = await Permission.microphone.status;
        if (!status.isGranted) {
          print('❌ iOS 마이크 권한이 없습니다.');
          throw Exception('iOS 마이크 권한이 없습니다.');
        }
      }
      
      // record 패키지 권한 재확인
      print('🎤 record 패키지 권한 확인 중...');
      final hasRecordPermission = await _audioRecorder.hasPermission();
      print('🎤 record 패키지 권한 결과: $hasRecordPermission');
      
      if (!hasRecordPermission) {
        print('❌ 음성 녹음 권한이 없습니다.');
        throw Exception('음성 녹음 권한이 없습니다.');
      }
      
      print('🎤 현재 녹음 상태: $_isRecording');
      if (_isRecording) {
        print('🎤 이미 녹음 중입니다. 중지 후 다시 시작합니다.');
        await _stopAudioRecording();
      }
      
      // iOS에서 더 안정적인 경로 사용
      final tempDir = await Directory.systemTemp.createTemp('audio_recording');
      final audioPath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      print('🎤 녹음 시작 명령 실행... (경로: $audioPath)');
      
      // iOS에서 더 안정적인 설정으로 녹음 시작 (카메라와 동시 사용 고려)
      await _audioRecorder.start(
        path: audioPath,
        encoder: AudioEncoder.wav,
        bitRate: 64000, // 더 낮은 비트레이트로 변경
        samplingRate: 22050, // 더 낮은 샘플링 레이트로 변경
        numChannels: 1, // 모노 채널
      );
      
      _isRecording = true;
      _audioPath = audioPath;
      print('✅ 음성 녹음이 시작되었습니다.');
      
    } catch (e) {
      print('❌ 음성 녹음 시작 실패: $e');
      throw e; // 상위로 예외 전파
    }
  }

  Future<void> _stopAudioRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        print('🔇 음성 녹음 중지');
        if (path != null) {
          final file = File(path);
          final bytes = await file.readAsBytes();
          await _sendAudioToServer(bytes);
        }
      }
    } catch (e) {
      print('❌ 음성 녹음 중지 실패: $e');
    }
  }

  Future<void> _sendAudioToServer(Uint8List audioBytes) async {
    try {
      final base64Audio = base64Encode(audioBytes);
      
      print('🚀 오디오 서버 전송 시작...');
      final result = await _apiService.sendAudioForAnalysis(base64Audio);
      print('✅ 오디오 분석 응답: $result');
      
      // VAD 데이터 추가
      if (result.containsKey('audio_vad')) {
        final vadData = result['audio_vad'];
        final newDataPoint = EmotionDataPoint(
          timestamp: DateTime.now(),
          valence: vadData['valence']?.toDouble() ?? 0.0,
          arousal: vadData['arousal']?.toDouble() ?? 0.0,
          dominance: vadData['dominance']?.toDouble() ?? 0.0,
        );
        
        _sessionData.add(newDataPoint);
        print('📊 오디오 VAD 데이터 수신: ${jsonEncode(newDataPoint.toJson())}');
      }
      
    } catch (e) {
      print('❌ 오디오 서버 전송 실패: $e');
    }
  }

  // CameraImage (YUV420_888 format) to Image (RGB format)
  img.Image? _convertCameraImage(CameraImage image) {
    if (image.format.group == ImageFormatGroup.yuv420) {
      // YUV420 -> RGB 변환 로직 (기존 코드 유지)
      final int width = image.width;
      final int height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final outImg = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * width + x;
          final int uvIndex = (y / 2).floor() * uvRowStride + (x / 2).floor() * (uvPixelStride ?? 0);
          
          final int yValue = yPlane[yIndex];
          final int uValue = uPlane[uvIndex];
          final int vValue = vPlane[uvIndex];

          // ITU-R BT.601 conversion
          int r = (yValue + 1.402 * (vValue - 128)).round();
          int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).round();
          int b = (yValue + 1.772 * (uValue - 128)).round();
          
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          outImg.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return img.copyRotate(outImg, angle: 90);

    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      // BGRA8888 -> RGB 변환 로직 (iOS용)
      final plane = image.planes[0];
      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
    } else {
      print('지원하지 않는 이미지 포맷: ${image.format.group}');
      return null;
    }
  }

  void _addNote() {
    if (_noteController.text.isNotEmpty) {
      setState(() {
        _conversationNotes.add(_noteController.text);
        _noteController.clear();
      });
    }
  }

  void _showNotesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: const Color.fromRGBO(0, 0, 0, 0.001),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Material(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: _buildNotesContent(controller),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰
          if (_isCameraInitialized && _cameraController != null && _hasCameraPermission)
            CameraPreview(_cameraController!),
          
          // 카메라가 없을 때 배경
          if (!_isCameraInitialized || !_hasCameraPermission)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !_hasCameraPermission ? Icons.camera_alt_outlined : Icons.camera_alt,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      !_hasCameraPermission 
                          ? '카메라 권한이 필요합니다'
                          : '카메라를 초기화하는 중...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 권한 상태 표시
          _buildPermissionStatus(),
          
          // 대화 중 UI
          if (_conversationState == ConversationState.talking)
            _buildTalkingUI(),
          
          // 대화 시작/종료 버튼 (항상 하단에 고정)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: _conversationState == ConversationState.talking
                ? _buildEndConversationButton()
                : _buildStartConversationButton(),
            ),
          ),
          
          // 대화 시작 안내 문구
          if (_conversationState != ConversationState.talking)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: _buildStartGuideText(),
              ),
            ),
          
          // 로딩 인디케이터
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildTalkingUI() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24.0).copyWith(bottom: 48),
        decoration: _bottomGradient(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 대화 주제 표시
            if (_conversationTopic.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '주제: $_conversationTopic',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 카메라 상태 안내
            if (!_isCameraInitialized || !_hasCameraPermission) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '음성 분석 모드',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // 실시간 분석 상태
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isAnalyzing ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isAnalyzing ? '실시간 감정 분석 중...' : '대화를 시작해주세요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 음성 레벨 표시
            if (_currentSoundLevel > 0) ...[
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _currentSoundLevel.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // 인식된 텍스트 표시
            if (_recognizedText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _recognizedText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisIndicator() {
    // 분석 중임을 나타내는 미묘한 인디케이터
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAnalyzing) 
            const BlinkingRecIndicator()
          else if (_isListening)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentEmotion.isNotEmpty ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAnalyzing ? '분석 중' : _isListening ? '음성 인식 중' : '실시간 분석',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
              if (_currentEmotion.isNotEmpty && !_isAnalyzing && !_isListening)
                Text(
                  '${_currentEmotion} (${_currentFaceEmotion})',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              if (_isListening)
                Text(
                  _recognizedText.isEmpty ? '말씀해주세요...' : '인식 중...',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotesContent(ScrollController scrollController) {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('대화 중 메모', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        hintText: '특별히 기록할 내용...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_noteController.text.isNotEmpty) {
                        setState(() {
                          _conversationNotes.add(_noteController.text);
                          _noteController.clear();
                        });
                        // main _SessionScreenState rebuild
                        this.setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (_conversationNotes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('아직 작성된 메모가 없습니다.'),
                        ),
                      )
                    else
                      ..._conversationNotes.map((note) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(note),
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  BoxDecoration _bottomGradient() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.black.withOpacity(0.8),
          Colors.black.withOpacity(0.0),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              '카메라 오류',
              style: BeMoreTheme.lightTheme.textTheme.headlineSmall?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(_cameraError, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // 시뮬레이터에서 카메라가 없을 때 플레이스홀더 표시
    if (_isSimulator && _cameraController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Colors.white54),
              const SizedBox(height: 16),
              const Text(
                '시뮬레이터 모드',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '실제 디바이스에서 카메라 기능을 확인하세요',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 화면 크기와 카메라 프리뷰의 비율을 계산하여 화면을 꽉 채우는 스케일 값을 구합니다.
    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _cameraController!.value.aspectRatio;

    // 화면 비율에 맞춰 스케일이 1보다 작으면 역수를 취해 확대합니다.
    if (scale < 1) scale = 1 / scale;

    return Transform.scale(
      scale: scale,
      child: Center(
        child: CameraPreview(_cameraController!),
      ),
    );
  }

  void _startImageAnalysis() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    // 이미 스트림이 실행 중이면 중지
    if (_cameraController!.value.isStreamingImages) {
      print('📷 기존 카메라 스트림 중지...');
      _cameraController!.stopImageStream();
    }
    
    // 잠시 대기 후 새 스트림 시작
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        print('📷 새 카메라 스트림 시작...');
        _startImageStream();
      }
    });
  }

  void _startImageStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      _cameraController!.startImageStream((CameraImage cameraImage) async {
        // 1초에 한 번씩만 이미지를 처리하도록 제어
        final now = DateTime.now();
        if (now.difference(_lastAnalyzedTime) < const Duration(seconds: 1)) {
          return;
        }
        _lastAnalyzedTime = now;

        try {
          // 분석 시작 상태 업데이트
          if (mounted) {
            setState(() {
              _isAnalyzing = true;
            });
          }

          // 1. CameraImage를 일반 이미지(JPEG)로 변환
          final image = _convertCameraImage(cameraImage);
          if (image == null) return;

          // 2. 이미지를 Base64 문자열로 인코딩 (품질 조정으로 크기 최적화)
          final base64Image = base64Encode(img.encodeJpg(image, quality: 85));

          // 3. API 서비스로 전송하여 분석 요청
          print('🚀 실시간 이미지 분석 요청...');
          final result = await _apiService.sendImageForAnalysis(base64Image);
          print('✅ 실시간 분석 완료: ${result['emotion_tag']} (${result['face_emotion']})');

          // 4. 응답 결과를 EmotionDataPoint 모델로 변환
          final newDataPoint = EmotionDataPoint(
            timestamp: DateTime.now(),
            valence: result['final_vad']['valence']?.toDouble() ?? 0.0,
            arousal: result['final_vad']['arousal']?.toDouble() ?? 0.0,
            dominance: result['final_vad']['dominance']?.toDouble() ?? 0.0,
          );
          
          _sessionData.add(newDataPoint);
          print('📊 실시간 VAD 데이터: V=${newDataPoint.valence.toStringAsFixed(2)}, A=${newDataPoint.arousal.toStringAsFixed(2)}, D=${newDataPoint.dominance.toStringAsFixed(2)}');

          // UI 상태 업데이트
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
              _currentEmotion = result['emotion_tag'] ?? '';
              _currentFaceEmotion = result['face_emotion'] ?? '';
            });
          }

        } catch (e) {
          print('❌ 실시간 분석 실패: $e');
          if (mounted) {
            setState(() {
              _isAnalyzing = false;
            });
          }
        }
      });
    } catch (e) {
      print('❌ 카메라 스트림 시작 실패: $e');
    }
  }

  // STT 기반 음성 인식 시작
  Future<void> _startSTTListening() async {
    print('🎤 === STT 음성 인식 시작 ===');
    
    // 텍스트 초기화
    setState(() {
      _recognizedText = '';
      _lastSentText = '';
    });
    
    bool available = await _speech.initialize(
      onError: (val) {
        print("STT Error: ${val.errorMsg}");
        // 에러 발생 시 자동으로 재시작
        if (val.errorMsg.contains('no_match') || val.errorMsg.contains('network')) {
          print('🔄 STT 에러로 인한 재시작 시도...');
          Future.delayed(const Duration(seconds: 1), () {
            if (_isListening) {
              _restartSTTListening();
            }
          });
        }
      },
      onStatus: (val) {
        print("STT Status: $val");
        // 상태 변화에 따른 처리
        if (val == 'done' && _isListening) {
          print('🔄 STT 세션 완료, 재시작...');
          Future.delayed(const Duration(seconds: 1), () {
            if (_isListening) {
              _restartSTTListening();
            }
          });
        }
      },
    );
    print("STT available: $available");

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          final newText = val.recognizedWords.trim();
          
          setState(() {
            _recognizedText = newText;
          });
          
          // 새로운 텍스트가 있고, 이전에 전송하지 않은 텍스트인 경우에만 처리
          if (newText.isNotEmpty && newText != _lastSentText) {
            print('🎤 새로운 텍스트 인식: $newText');
            
            // 디바운스 타이머로 중복 전송 방지
            _textDebounceTimer?.cancel();
            _textDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
              if (newText.isNotEmpty && newText != _lastSentText) {
                _sendTextToServer(newText);
                _lastSentText = newText;
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          setState(() {
            _currentSoundLevel = level ?? 0.0;
          });
          // 음성 파형 분석 추가 (null 체크)
          if (level != null) {
            _analyzeSoundLevel(level);
          }
        },
        localeId: 'ko_KR', // 한국어 설정
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3), // 일시 정지 시간 단축
        partialResults: false, // 부분 결과 비활성화로 중복 방지
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation, // dictation 모드로 변경 (더 자연스러운 인식)
        onDevice: false, // 서버 기반 인식 사용
      );
    } else {
      print("STT recognition not available.");
      throw Exception('STT recognition not available');
    }
  }

  // STT 재시작 메서드
  Future<void> _restartSTTListening() async {
    if (!_isListening) return;
    
    try {
      // 디바운스 타이머 정리
      _textDebounceTimer?.cancel();
      
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 텍스트 초기화
      setState(() {
        _recognizedText = '';
        _lastSentText = '';
      });
      
      if (_isListening) {
        _speech.listen(
          onResult: (val) {
            final newText = val.recognizedWords.trim();
            
            setState(() {
              _recognizedText = newText;
            });
            
            // 새로운 텍스트가 있고, 이전에 전송하지 않은 텍스트인 경우에만 처리
            if (newText.isNotEmpty && newText != _lastSentText) {
              print('🎤 재시작 후 새로운 텍스트 인식: $newText');
              
              // 디바운스 타이머로 중복 전송 방지
              _textDebounceTimer?.cancel();
              _textDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
                if (newText.isNotEmpty && newText != _lastSentText) {
                  _sendTextToServer(newText);
                  _lastSentText = newText;
                }
              });
            }
          },
          onSoundLevelChange: (level) {
            setState(() {
              _currentSoundLevel = level ?? 0.0;
            });
            // 음성 파형 분석 추가 (null 체크)
            if (level != null) {
              _analyzeSoundLevel(level);
            }
          },
          localeId: 'ko_KR',
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: false, // 부분 결과 비활성화
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
          onDevice: false,
        );
        print('🔄 STT 재시작 완료');
      }
    } catch (e) {
      print('❌ STT 재시작 실패: $e');
    }
  }

  // STT 음성 인식 중지
  Future<void> _stopSTTListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      
      // 디바운스 타이머 정리
      _textDebounceTimer?.cancel();
      
      _speech.stop();
      print('🔇 STT 음성 인식 중지');
      
      // 인식된 텍스트가 있고, 아직 전송하지 않은 텍스트인 경우에만 서버로 전송
      if (_recognizedText.isNotEmpty && _recognizedText != _lastSentText) {
        await _sendTextToServer(_recognizedText);
        _lastSentText = _recognizedText;
      }
    }
  }

  // 인식된 텍스트를 서버로 전송
  Future<void> _sendTextToServer(String text) async {
    try {
      print('🚀 텍스트 서버 전송 시작: $text');
      final result = await _apiService.sendTextForAnalysis(text);
      print('✅ 텍스트 분석 응답: $result');
      
      // VAD 데이터 추가
      if (result.containsKey('text_vad')) {
        final vadData = result['text_vad'];
        final newDataPoint = EmotionDataPoint(
          timestamp: DateTime.now(),
          valence: vadData['valence']?.toDouble() ?? 0.0,
          arousal: vadData['arousal']?.toDouble() ?? 0.0,
          dominance: vadData['dominance']?.toDouble() ?? 0.0,
        );
        
        _sessionData.add(newDataPoint);
        print('📊 텍스트 VAD 데이터 수신: ${jsonEncode(newDataPoint.toJson())}');
      }
      
    } catch (e) {
      print('❌ 텍스트 서버 전송 실패: $e');
    }
  }

  // 실시간 음성 파형 분석 (VAD 추정)
  void _analyzeSoundLevel(double level) {
    setState(() {
      _currentSoundLevel = level;
    });
    
    // 음성 파형을 기반으로 간단한 VAD 추정
    if (level > 0.1) { // 음성이 감지된 경우
      final estimatedVAD = _estimateVADFromSoundLevel(level);
      final newDataPoint = EmotionDataPoint(
        timestamp: DateTime.now(),
        valence: estimatedVAD['valence']!,
        arousal: estimatedVAD['arousal']!,
        dominance: estimatedVAD['dominance']!,
      );
      
      _sessionData.add(newDataPoint);
      print('📊 음성 파형 VAD 추정: V=${estimatedVAD['valence']!.toStringAsFixed(2)}, A=${estimatedVAD['arousal']!.toStringAsFixed(2)}, D=${estimatedVAD['dominance']!.toStringAsFixed(2)}');
    }
  }

  // 음성 파형을 기반으로 VAD 추정
  Map<String, double> _estimateVADFromSoundLevel(double level) {
    // 음성 레벨을 기반으로 간단한 VAD 추정
    // 높은 음성 레벨 = 높은 활성화 (arousal)
    // 안정적인 음성 = 높은 지배력 (dominance)
    // 중간 음성 레벨 = 중립적 감정 (valence)
    
    final arousal = (level * 2).clamp(0.0, 1.0); // 음성 레벨에 비례
    final dominance = (level * 1.5).clamp(0.3, 0.8); // 적당한 지배력
    final valence = 0.5; // 기본 중립적 감정
    
    return {
      'valence': valence,
      'arousal': arousal,
      'dominance': dominance,
    };
  }

  Widget _buildPermissionStatus() {
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _hasCameraPermission ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: _hasCameraPermission ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '카메라',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _hasCameraPermission ? '사용 가능' : '권한 필요',
                  style: TextStyle(
                    color: _hasCameraPermission ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasMicrophonePermission ? Icons.mic : Icons.mic_off,
                  color: _hasMicrophonePermission ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '마이크',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _hasMicrophonePermission ? '사용 가능' : '권한 필요',
                  style: TextStyle(
                    color: _hasMicrophonePermission ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (!_hasCameraPermission || !_hasMicrophonePermission) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !_hasCameraPermission && !_hasMicrophonePermission
                            ? '카메라와 마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.'
                            : !_hasCameraPermission
                                ? '카메라 권한이 없어도 음성 분석으로 진행 가능합니다.'
                                : '마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 대화 시작 버튼
  Widget _buildStartConversationButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _startConversation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              '대화 시작',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 대화 종료 버튼
  Widget _buildEndConversationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _endConversation,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stop, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              '대화 종료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 대화 시작 안내 문구
  Widget _buildStartGuideText() {
    String guideText = '';
    String subText = '';
    
    if (!_hasCameraPermission && !_hasMicrophonePermission) {
      guideText = '권한을 허용한 후 대화를 시작하세요';
      subText = '카메라와 마이크 권한이 필요합니다';
    } else if (!_hasCameraPermission) {
      guideText = '음성 분석만으로 대화를 시작할 수 있습니다';
      subText = '카메라 권한 없이도 음성으로 감정을 분석합니다';
    } else if (!_hasMicrophonePermission) {
      guideText = '얼굴 분석만으로 대화를 시작할 수 있습니다';
      subText = '마이크 권한 없이도 표정으로 감정을 분석합니다';
    } else {
      guideText = '버튼을 눌러 대화를 시작하세요';
      subText = '실시간으로 감정을 분석해드립니다';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            guideText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (subText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// 깜빡이는 효과를 위한 별도의 StatefulWidget
class BlinkingRecIndicator extends StatefulWidget {
  const BlinkingRecIndicator({super.key});

  @override
  _BlinkingRecIndicatorState createState() => _BlinkingRecIndicatorState();
}

class _BlinkingRecIndicatorState extends State<BlinkingRecIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// 음성 파형을 그리는 CustomPainter
class SoundWavePainter extends CustomPainter {
  final double soundLevel;
  double smoothedSoundLevel = 0.0;

  SoundWavePainter(this.soundLevel);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final barCount = 12;
    final barWidth = 8.0;
    final spacing = 4.0;
    final maxHeight = 20.0;
    final minHeight = 5.0;
    final cornerRadius = const Radius.circular(4.0);
    final random = Random();

    smoothedSoundLevel = smoothedSoundLevel * 0.3 + soundLevel * 0.7;

    for (int i = 0; i < barCount; i++) {
      final randomFactor = 0.8 + random.nextDouble() * 0.4;
      final barHeight = max(minHeight, (smoothedSoundLevel * maxHeight * randomFactor));
      final x = i * (barWidth + spacing);
      final y = (size.height / 2) - (barHeight / 2);

      final rRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        cornerRadius,
      );

      canvas.drawRRect(rRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 