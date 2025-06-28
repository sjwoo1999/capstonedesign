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
import '../../services/audio_manager.dart'; // AudioManager 추가
import '../../utils/permission_helper.dart'; // PermissionHelper 추가
import 'dart:typed_data';
import 'dart:io';
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

class _SessionScreenState extends State<SessionScreen> with WidgetsBindingObserver {
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

  // 오디오 관련
  final AudioManager _audioManager = AudioManager();
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

  // 권한 안내 다이얼로그 중복 방지 플래그
  bool _cameraSettingsDialogShown = false;
  bool _micSettingsDialogShown = false;
  bool _isRequestingPermissions = false; // 권한 요청 중 플래그 추가
  bool _hasCheckedPermissions = false; // 초기 권한 확인 완료 플래그 추가

  // STT 재시작 관련 플래그들
  bool _isRestarting = false;
  int _consecutiveEmptyResults = 0;
  DateTime? _lastMeaningfulText;

  @override
  void initState() {
    super.initState();
    print('🚀 실시간 대화 화면 초기화 시작');
    
    // API 서비스 초기화
    _apiService = EmotionAPIService();
    
    // AudioManager 초기화
    _initializeAudioManager();
    
    _initializeDeviceInfo();
    
    WidgetsBinding.instance.addObserver(this); // 라이프사이클 옵저버 등록
    
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
    WidgetsBinding.instance.removeObserver(this); // 옵저버 해제
    _topicController.dispose();
    _noteController.dispose();
    
    // 텍스트 디바운스 타이머 정리
    _textDebounceTimer?.cancel();
    
    // 카메라 컨트롤러 정리
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    
    // AudioManager 정리
    _audioManager.dispose();
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasCheckedPermissions) {
      print('🔄 앱이 포그라운드로 복귀, 권한 상태만 확인');
      _checkPermissionStatusOnly(); // 권한 요청 없이 상태만 확인
    }
  }

  // 권한 상태만 확인 (요청 없음)
  Future<void> _checkPermissionStatusOnly() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      
      if (mounted) {
        setState(() {
          _hasCameraPermission = cameraStatus.isGranted;
          _hasMicrophonePermission = micStatus.isGranted;
        });
      }
    } catch (e) {
      print('❌ 권한 상태 확인 중 오류: $e');
    }
  }

  // iOS에서 권한 인식을 위한 카메라 프리뷰 강제 활성화
  Future<void> _forceCameraPreviewForPermission() async {
    if (_isSimulator || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    try {
      print('📷 iOS 권한 인식을 위한 카메라 프리뷰 강제 활성화');
      
      // 카메라 스트림 시작
      await _cameraController!.startImageStream((image) {
        // 권한 인식 목적이므로 실제 처리는 하지 않음
      });
      
      // 3초간 카메라 활성화 유지
      await Future.delayed(const Duration(seconds: 3));
      
      // 카메라 스트림 중지
      await _cameraController!.stopImageStream();
      
      print('📷 카메라 프리뷰 강제 활성화 완료');
    } catch (e) {
      print('❌ 카메라 프리뷰 강제 활성화 실패: $e');
    }
  }

  // 카메라 재시도 메서드
  Future<void> _retryCamera() async {
    print('🔄 카메라 재시도 시작');
    
    setState(() {
      _cameraError = '';
      _isCameraInitialized = false;
    });
    
    try {
      // 기존 카메라 컨트롤러 정리
      await _cameraController?.dispose();
      _cameraController = null;
      
      // 카메라 재초기화
      await _initializeCameraWithPermissionRequest();
      
      print('✅ 카메라 재시도 성공');
    } catch (e) {
      print('❌ 카메라 재시도 실패: $e');
      setState(() {
        _cameraError = '카메라 재시도 실패: $e';
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _checkPermissions() async {
    if (_isRequestingPermissions || _hasCheckedPermissions) {
      print('⚠️ 권한 확인 중이거나 이미 확인됨');
      return;
    }
    
    _isRequestingPermissions = true;
    
    try {
      // iOS에서 권한 요청이 무시되는 문제를 해결하기 위해
      // 먼저 카메라 초기화를 시도하고, 그 과정에서 권한을 요청
      if (!_isSimulator) {
        print('📷 iOS 권한 문제 해결을 위해 카메라 초기화 먼저 시도');
        await _initializeCameraWithPermissionRequest();
      }
      
      // 마이크 권한 확인
      _hasMicrophonePermission = await PermissionHelper.requestMicrophonePermission(context);
      
      _hasCheckedPermissions = true;
      
      // 시뮬레이터 처리
      if (_isSimulator) {
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _conversationState = ConversationState.ready;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _conversationState = ConversationState.ready;
          });
        }
      }
    } finally {
      _isRequestingPermissions = false;
    }
  }

  // 카메라 초기화와 권한 요청을 함께 처리
  Future<void> _initializeCameraWithPermissionRequest() async {
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

      // 전면 카메라 목록 필터링 및 로그 출력
      final frontCameras = cameras.where((camera) => camera.lensDirection == CameraLensDirection.front).toList();
      print('📷 사용 가능한 모든 전면 카메라:');
      for (var cam in frontCameras) {
        print('  - 이름: \\${cam.name}, 방향: \\${cam.lensDirection}, 해상도: \\${cam.sensorOrientation}');
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
      
      // 가장 표준적인(일반 화각, wide가 아닌) 전면 카메라 우선 선택
      CameraDescription selectedCamera = frontCameras.first;
      if (frontCameras.length > 1) {
        final standardCamera = frontCameras.firstWhere(
          (c) => !c.name.toLowerCase().contains('wide'),
          orElse: () => frontCameras.first,
        );
        selectedCamera = standardCamera;
      }
      print('📷 선택된 카메라: \\${selectedCamera.name}');

      // 기존 컨트롤러 정리
      await _cameraController?.dispose();
      
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.high, // 해상도 명확히 지정
        enableAudio: false,
      );

      // 카메라 초기화 시도 (이 과정에서 iOS가 권한을 요청할 수 있음)
      print('📷 카메라 초기화 시도 중... (권한 요청 포함)');
      await _cameraController!.initialize();
      print('✅ 카메라 초기화 성공');
      
      // 카메라 권한 상태 확인
      final cameraStatus = await Permission.camera.status;
      _hasCameraPermission = cameraStatus.isGranted;
      
      if (_hasCameraPermission) {
        print('✅ 카메라 권한 확인됨');
        // iOS 권한 인식을 위한 카메라 프리뷰 강제 활성화
        await _forceCameraPreviewForPermission();
      } else {
        print('❌ 카메라 권한이 없음, 권한 요청 다이얼로그 표시');
        // 권한이 없으면 사용자에게 설명 후 요청
        _hasCameraPermission = await PermissionHelper.requestCameraPermission(context);
        
        if (_hasCameraPermission) {
          // 권한이 허용되었다면 다시 카메라 프리뷰 활성화
          await _forceCameraPreviewForPermission();
        }
      }
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
      
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
      
      // 카메라 초기화 실패 시 권한 문제일 수 있으므로 권한 요청
      if (e.toString().contains('permission') || e.toString().contains('denied')) {
        print('📱 카메라 권한 문제로 추정, 권한 요청 다이얼로그 표시');
        _hasCameraPermission = await PermissionHelper.requestCameraPermission(context);
      }
      
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

  void _startConversation() {
    // 이미 대화 중이면 중복 시작 방지
    if (_conversationState == ConversationState.talking) {
      print('⚠️ 이미 대화 중입니다.');
      return;
    }
    
    print('🎤 === 대화 시작 ===');
    print('📱 카메라 권한: $_hasCameraPermission, 마이크 권한: $_hasMicrophonePermission');
    
    setState(() {
      _conversationState = ConversationState.talking;
      _conversationStartTime = DateTime.now();
      // 텍스트 초기화
      _recognizedText = '';
      _lastSentText = '';
    });
    
    // STT 중지 상태 확인 후 시작
    if (_isListening) {
      print('⚠️ STT가 이미 실행 중입니다. 중지 후 재시작합니다.');
      _audioManager.stopSTT().then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _startVoiceAnalysis();
        });
      });
    } else {
      // 카메라와 음성 분석 시작
      if (_isCameraInitialized && _cameraController != null && _hasCameraPermission) {
        print('🎤 멀티모달 대화 시작: ${_conversationTopic.isNotEmpty ? _conversationTopic : "자유 대화"}');
        _startImageAnalysis();
        _startVoiceAnalysis();
      } else {
        print('🎤 음성 분석만으로 대화 시작: ${_conversationTopic.isNotEmpty ? _conversationTopic : "자유 대화"}');
        _startVoiceAnalysis();
      }
    }
  }

  // 음성 분석 시작 (AudioManager 사용)
  Future<void> _startVoiceAnalysis() async {
    if (!mounted) return;
    
    print('🎤 === AudioManager 음성 분석 시작 ===');
    
    try {
      // 새로운 STT 세션 시작 (AudioManager 사용)
      final success = await _audioManager.startSTTOnly(
        localeId: 'ko-KR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      
      if (success) {
        print('🔄 STT 재시작 완료');
        if (mounted) {
          setState(() {
            _isListening = true;
          });
        }
        print('✅ AudioManager STT 시작 성공');
      } else {
        print('❌ STT 재시작 실패');
      }
      
    } catch (e) {
      print('❌ AudioManager 음성 분석 시작 중 오류: $e');
    }
  }

  void _processRecognizedText(String text) {
    if (!mounted || _conversationState != ConversationState.talking) return;
    
    print('🔍 텍스트 필터링 검사 시작: "$text"');
    
    // 의미 없는 텍스트 필터링 (개선된 버전)
    if (_isMeaninglessText(text)) {
      print('🚫 의미 없는 텍스트 필터링: $text');
      _consecutiveEmptyResults++;
      return;
    }
    
    // 중복 텍스트 방지
    if (text == _lastSentText) {
      print('🚫 중복 텍스트 방지: $text');
      return;
    }
    
    print('✅ 의미 있는 텍스트로 인식: $text');
    
    // 의미 있는 텍스트 처리
    _consecutiveEmptyResults = 0;
    _lastMeaningfulText = DateTime.now();
    
    setState(() {
      _recognizedText = text;
    });
    
    // 디바운스 타이머 정리
    _textDebounceTimer?.cancel();
    
    // 1초 후 서버로 전송 (중복 방지)
    _textDebounceTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && _conversationState == ConversationState.talking) {
        _sendTextToServer(text);
        _lastSentText = text;
      }
    });
  }
  
  bool _isMeaninglessText(String text) {
    // 숫자만 있는 경우
    if (RegExp(r'^[\d\s\-]+$').hasMatch(text)) {
      print('🚫 필터링: 숫자만 있는 텍스트');
      return true;
    }
    
    // 숫자와 한국어가 혼재된 이상한 패턴 (예: "123-456-789 열")
    if (RegExp(r'\d+.*[가-힣]+.*\d+').hasMatch(text)) {
      print('🚫 필터링: 숫자와 한국어 혼재 패턴');
      return true;
    }
    
    // 연속된 숫자 패턴 (전화번호, 주민번호 등)
    if (RegExp(r'\d{3,}.*\d{3,}.*\d{3,}').hasMatch(text)) {
      print('🚫 필터링: 연속된 숫자 패턴');
      return true;
    }
    
    // 테스트 관련 단어들 필터링
    final testWords = ['마이크', '테스트', 'test', 'microphone', 'mic', 'check', '체크'];
    final lowerText = text.toLowerCase();
    if (testWords.any((word) => lowerText.contains(word))) {
      print('🚫 필터링: 테스트 관련 단어 포함');
      return true;
    }
    
    // 단일 단어이면서 3글자 미만
    final words = text.split(' ').where((word) => word.isNotEmpty).toList();
    if (words.length == 1 && words[0].length < 3) {
      print('🚫 필터링: 단일 단어 3글자 미만');
      return true;
    }
    
    // 의미 없는 반복 패턴 (50% 이상 중복)
    if (words.length > 1) {
      final uniqueWords = words.toSet();
      if (uniqueWords.length < words.length * 0.5) {
        print('🚫 필터링: 의미 없는 반복 패턴');
        return true;
      }
    }
    
    // 일반적인 노이즈 단어들 (영어 + 한국어)
    final noiseWords = [
      'um', 'uh', 'ah', 'oh', 'hmm', 'well', 'like', 'you know', 'i mean',
      '음', '어', '아', '오', '흠', '그', '저', '뭐', '이', '그게', '뭐냐',
      '하나', '둘', '셋', '넷', '다섯', '여섯', '일곱', '여덟', '아홉', '열',
      'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'
    ];
    
    final lowerWords = words.map((word) => word.toLowerCase()).toList();
    if (lowerWords.every((word) => noiseWords.contains(word))) {
      print('🚫 필터링: 노이즈 단어만 포함');
      return true;
    }
    
    // 50% 이상이 노이즈 단어인 경우
    final noiseCount = lowerWords.where((word) => noiseWords.contains(word)).length;
    if (noiseCount >= lowerWords.length * 0.5) {
      print('🚫 필터링: 50% 이상 노이즈 단어');
      return true;
    }
    
    return false;
  }

  // STT 에러 처리
  void _handleSTTError(String errorMsg) {
    print('🔄 STT 에러로 인한 재시작: $errorMsg');
    
    // error_no_match는 정상적인 상황이므로 재시작하지 않음
    if (errorMsg.contains('no_match')) {
      print('ℹ️ 음성 인식 없음 (정상적인 상황)');
      _consecutiveEmptyResults++;
      return;
    }
    
    // 네트워크나 오디오 관련 에러만 재시작
    if (errorMsg.contains('network') || 
        errorMsg.contains('audio') ||
        errorMsg.contains('timeout') ||
        errorMsg.contains('permission')) {
      _scheduleSTTRestart();
    }
  }

  // STT 완료 처리
  void _handleSTTCompletion() {
    print('🔄 STT 세션 완료, 재시작 고려 중...');
    
    // 대화가 끝났거나 앱이 종료 중이면 재시작하지 않음
    if (_conversationState != ConversationState.talking || !mounted) {
      print('⏸️ 대화 종료 중이므로 재시작하지 않음');
      return;
    }
    
    // 연속으로 빈 결과가 나온 경우에만 재시작 (5회 이상)
    if (_consecutiveEmptyResults >= 5) {
      print('🔄 연속 빈 결과로 인한 재시작 (${_consecutiveEmptyResults}회)');
      _scheduleSTTRestart();
      return;
    }
    
    // 마지막 의미 있는 텍스트로부터 60초가 지난 경우 재시작
    if (_lastMeaningfulText != null) {
      final timeSinceLastText = DateTime.now().difference(_lastMeaningfulText!);
      if (timeSinceLastText.inSeconds > 60) {
        print('🔄 오랫동안 텍스트 없음으로 인한 재시작 (${timeSinceLastText.inSeconds}초)');
        _scheduleSTTRestart();
        return;
      }
    }
    
    // 그 외의 경우는 자동 재시작하지 않음
    print('⏸️ STT 세션 완료, 자동 재시작하지 않음');
  }

  // STT 재시작 스케줄링
  void _scheduleSTTRestart() {
    if (_isRestarting) {
      print('⚠️ 이미 재시작 중입니다');
      return;
    }
    
    _isRestarting = true;
    
    // 2초 후 재시작
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _conversationState == ConversationState.talking) {
        _restartSTT();
      } else {
        _isRestarting = false;
      }
    });
  }

  // STT 재시작 메서드 (AudioManager 사용)
  Future<void> _restartSTT() async {
    if (!mounted || _conversationState != ConversationState.talking || _isRestarting) {
      print('⚠️ STT 재시작 조건 불충족');
      _isRestarting = false;
      return;
    }
    
    try {
      print('🔄 STT 재시작 시작...');
      
      // 기존 STT 중지
      await _audioManager.stopSTT();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 상태 재확인
      if (!mounted || _conversationState != ConversationState.talking) {
        print('⚠️ STT 재시작 중 상태 변경됨');
        _isRestarting = false;
        return;
      }
      
      // 텍스트 초기화
      setState(() {
        _recognizedText = '';
        _lastSentText = '';
      });
      
      // 새로운 STT 세션 시작 (AudioManager 사용)
      final success = await _audioManager.startSTTOnly(
        localeId: 'ko-KR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
      
      if (success) {
        print('🔄 STT 재시작 완료');
      } else {
        print('❌ STT 재시작 실패');
      }
      
      print('🔄 STT 재시작 완료');
      _isRestarting = false;
      
    } catch (e) {
      print('❌ STT 재시작 실패: $e');
      _isRestarting = false;
    }
  }

  void _endConversation() {
    if (_conversationState != ConversationState.talking) {
      print('⚠️ 대화 중이 아닙니다.');
      return;
    }
    
    print('🔚 === 대화 종료 시작 ===');
    
    setState(() {
      _conversationState = ConversationState.ending;
    });
    
    // AudioManager 중지
    _audioManager.stopAll();
    
    // 카메라 스트림 중지
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
    
    // 텍스트 디바운스 타이머 정리
    _textDebounceTimer?.cancel();
    
    _conversationEndTime = DateTime.now();
    
    print('🔚 대화 종료, 분석 데이터 (${_sessionData.length}개) 전송 준비');
    
    // 세션 데이터 전송
    _sendSessionData();
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

  // STT 음성 인식 중지
  Future<void> _stopSTTListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });
      
      // 디바운스 타이머 정리
      _textDebounceTimer?.cancel();
      
      _audioManager.stopSTT();
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
    if (!mounted || _conversationState != ConversationState.talking) return;
    
    print('🚀 텍스트 서버 전송 시작: $text');
    
    try {
      // 텍스트 기반 VAD 추정
      final estimatedVAD = _audioManager.estimateVADFromText(text);
      print('📊 텍스트 기반 VAD 추정: ${estimatedVAD.toStringAsFixed(2)}');
      
      // 서버로 텍스트 분석 요청
      final result = await _apiService.analyzeTextEmotion(text);
      
      if (result != null) {
        print('✅ 텍스트 분석 성공');
        
        // VAD 데이터 생성 (텍스트 기반 추정값 사용)
        final vadData = {
          'valence': estimatedVAD,
          'arousal': estimatedVAD,
          'dominance': estimatedVAD,
        };
        
        // 세션 데이터에 추가
        final newDataPoint = EmotionDataPoint.fromVad(
          timestamp: DateTime.now(),
          vad: vadData,
          text: text,
          emotion: result['text_emotion'] ?? 'neutral',
          confidence: 0.8, // 텍스트 기반이므로 중간 신뢰도
        );
        
        _sessionData.add(newDataPoint);
        
        print('📊 텍스트 VAD 데이터 생성: ${jsonEncode(newDataPoint.toJson())}');
        
        // 실시간 분석 결과 업데이트
        if (mounted) {
          setState(() {
            _currentEmotion = result['text_emotion'] ?? 'neutral';
          });
        }
        
      } else {
        print('❌ 텍스트 분석 실패');
      }
      
    } catch (e) {
      print('❌ 텍스트 서버 전송 중 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰
          _buildCameraPreview(),
          
          // 권한 상태 표시
          _buildPermissionStatus(),
          
          // 대화 중 UI (버튼과 겹치지 않도록 조정)
          if (_conversationState == ConversationState.talking)
            _buildTalkingUI(),
          
          // 대화 시작 안내 문구 (대화 중이 아닐 때만)
          if (_conversationState != ConversationState.talking)
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Center(
                child: _buildStartGuideText(),
              ),
            ),
          
          // 대화 시작/종료 버튼 (항상 최하단에 고정)
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
        padding: const EdgeInsets.all(24.0).copyWith(bottom: 120), // 버튼 공간 확보
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
                  widthFactor: (_currentSoundLevel / 100).clamp(0.0, 1.0),
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
            ],
          ],
        ),
      ),
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

  Widget _buildCameraPreview() {
    if (_cameraError.isNotEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                '카메라 오류',
                style: BeMoreTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _cameraError,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retryCamera,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const CircularProgressIndicator(
                  color: Colors.blue,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '카메라 초기화 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 시뮬레이터에서 카메라가 없을 때 플레이스홀더 표시
    if (_isSimulator && _cameraController == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.camera_alt, size: 80, color: Colors.white54),
              ),
              const SizedBox(height: 24),
              const Text(
                '시뮬레이터 모드',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '실제 디바이스에서 카메라 기능을 확인하세요',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 실제 카메라 프리뷰 - 화면을 꽉 채우도록 개선
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.width ?? 1,
              height: _cameraController!.value.previewSize?.height ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionStatus() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '권한 상태',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 카메라 권한
            _buildPermissionItem(
              icon: _hasCameraPermission ? Icons.camera_alt : Icons.camera_alt_outlined,
              title: '카메라',
              isGranted: _hasCameraPermission,
              description: _hasCameraPermission ? '표정 분석 가능' : '표정 분석 불가',
            ),
            
            const SizedBox(height: 12),
            
            // 마이크 권한
            _buildPermissionItem(
              icon: _hasMicrophonePermission ? Icons.mic : Icons.mic_off,
              title: '마이크',
              isGranted: _hasMicrophonePermission,
              description: _hasMicrophonePermission ? '음성 분석 가능' : '음성 분석 불가',
            ),
            
            // 권한이 없는 경우 안내
            if (!_hasCameraPermission || !_hasMicrophonePermission) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        !_hasCameraPermission && !_hasMicrophonePermission
                            ? '카메라와 마이크 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'
                            : !_hasCameraPermission
                                ? '카메라 권한이 없어도 음성 분석으로 진행 가능합니다.'
                                : '마이크 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          height: 1.4,
                        ),
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

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required bool isGranted,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGranted 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isGranted 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isGranted ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: isGranted ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isGranted ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // 대화 시작 버튼
  Widget _buildStartConversationButton() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startConversation,
          borderRadius: BorderRadius.circular(70),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '시작',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 대화 종료 버튼
  Widget _buildEndConversationButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 테스트용 더미 텍스트 버튼
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 3,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // 테스트용 더미 텍스트
                _processRecognizedText("안녕하세요 오늘 기분이 좋습니다");
              },
              borderRadius: BorderRadius.circular(40),
              child: const Center(
                child: Icon(
                  Icons.text_fields,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 24),
        
        // 대화 종료 버튼
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF44336).withOpacity(0.4),
                blurRadius: 25,
                spreadRadius: 8,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _endConversation,
              borderRadius: BorderRadius.circular(70),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 4),
                      Text(
                        '종료',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      guideText = '음성 분석으로 대화를 시작할 수 있습니다';
      subText = '카메라 권한 없이도 음성으로 감정을 분석합니다';
    } else if (!_hasMicrophonePermission) {
      guideText = '얼굴 분석으로 대화를 시작할 수 있습니다';
      subText = '마이크 권한 없이도 표정으로 감정을 분석합니다';
    } else {
      guideText = '버튼을 눌러 대화를 시작하세요';
      subText = '실시간으로 감정을 분석합니다';
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

  // AudioManager 초기화
  Future<void> _initializeAudioManager() async {
    try {
      final success = await _audioManager.initialize(
        onTextRecognized: (text) {
          print('🎤 AudioManager 텍스트 인식: $text');
          _processRecognizedText(text);
        },
        onSoundLevelChanged: (level) {
          if (mounted) {
            setState(() {
              _currentSoundLevel = level;
            });
          }
        },
        onError: (error) {
          print('❌ AudioManager 오류: $error');
        },
      );
      
      if (success) {
        print('✅ AudioManager 초기화 성공');
      } else {
        print('❌ AudioManager 초기화 실패');
      }
    } catch (e) {
      print('❌ AudioManager 초기화 중 오류: $e');
    }
  }

  // 세션 데이터 전송 및 분석 화면 이동
  Future<void> _sendSessionData() async {
    try {
      print('📦 세션 데이터 전송 시작...');
      
      // 실제 앱에서는 여기서 서버로 _sessionData를 json으로 변환하여 전송합니다.
      final payload = jsonEncode(_sessionData.map((d) => d.toJson()).toList());
      print('📦 전송될 최종 데이터: $payload');
      
      // 분석 화면으로 이동
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AnalysisPendingScreen(sessionData: _sessionData)),
           // 현재까지의 모든 라우트를 스택에서 제거
        );
      }
      
    } catch (e) {
      print('❌ 세션 데이터 전송 실패: $e');
      
      // 에러가 발생해도 분석 화면으로 이동
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => AnalysisPendingScreen(sessionData: _sessionData)),
          
        );
      }
    }
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