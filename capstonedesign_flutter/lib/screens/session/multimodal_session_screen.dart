import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/emotion_provider.dart';
import '../../services/audio_manager.dart';
import '../../models/emotion_data_point.dart';
import '../../theme/bemore_theme.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../analysis/analysis_result_screen.dart';
import '../analysis/analysis_pending_screen.dart';

// Make this function available to all classes in this file
List<Color> getSfHighlightColors(Color base) {
  return [
    base,
    Colors.white,
    Colors.cyanAccent,
    Colors.purpleAccent,
  ];
}

/// 멀티모달 감정 분석 세션 화면
/// 영상, 음성, 텍스트 세 가지 모달리티를 통합하여 실시간 감정 분석
class MultimodalSessionScreen extends StatefulWidget {
  const MultimodalSessionScreen({super.key});

  @override
  State<MultimodalSessionScreen> createState() => _MultimodalSessionScreenState();
}

class _MultimodalSessionScreenState extends State<MultimodalSessionScreen> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  // 세션 상태
  bool _isSessionActive = false;
  bool _isAnalyzing = false;
  String _currentEmotion = 'neutral';
  double _currentConfidence = 0.0;
  
  // 카메라 관련
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  
  // 오디오 관련
  final AudioManager _audioManager = AudioManager();
  bool _isListening = false;
  String _recognizedText = '';
  double _currentSoundLevel = 0.0;
  
  // 분석 데이터
  final List<EmotionDataPoint> _sessionData = [];
  
  // 타이머
  Timer? _analysisTimer;
  Timer? _textDebounceTimer;
  Timer? _sessionTimer;
  
  // UI 상태
  String _statusMessage = '세션을 시작하세요';
  String _analysisSummary = '';
  bool _showCameraPreview = false;
  DateTime? _lastAnalyzedTime;

  // 애니메이션 컨트롤러
  late AnimationController _waveController;
  late AnimationController _particleController;
  late AnimationController _emotionController;
  
  // 파티클 시스템
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 애니메이션 컨트롤러 초기화
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _emotionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _initializeSession();
    _generateParticles();
  }

  @override
  void dispose() {
    print('🗑️ [Session] 멀티모달 세션 화면 dispose 시작');
    
    // 애니메이션 컨트롤러 정리
    _waveController.dispose();
    _particleController.dispose();
    _emotionController.dispose();
    
    // 모든 타이머 정리
    _analysisTimer?.cancel();
    _textDebounceTimer?.cancel();
    _sessionTimer?.cancel();
    
    // 카메라 정리
    _cameraController?.dispose();
    
    // 오디오 매니저 정리
    _audioManager.stopSTT();
    
    // STT 콜백 제거
    _audioManager.onTextRecognized = null;
    _audioManager.onError = null;
    
    print('🗑️ [Session] 멀티모달 세션 화면 dispose 완료');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pauseSession();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSession();
    }
  }

  /// 세션 초기화
  Future<void> _initializeSession() async {
    print('🚀 멀티모달 세션 초기화 시작');
    
    // 권한 확인
    await _checkPermissions();
    
    // 카메라 초기화
    if (_hasCameraPermission) {
      await _initializeCamera();
    }
    
    // 오디오 매니저 초기화
    await _initializeAudioManager();
    
    setState(() {
      _statusMessage = '세션 시작 준비 완료';
    });
  }

  /// 권한 확인
  Future<void> _checkPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;
      
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (result.isGranted) {
          print('✅ 카메라 권한 허용됨');
        }
      }
      
      if (!micStatus.isGranted) {
        final result = await Permission.microphone.request();
        if (result.isGranted) {
          print('✅ 마이크 권한 허용됨');
        }
      }
      
      final finalCameraStatus = await Permission.camera.status;
      setState(() {
        _hasCameraPermission = finalCameraStatus.isGranted;
      });
      
    } catch (e) {
      print('❌ 권한 확인 중 오류: $e');
    }
  }

  /// 카메라 초기화
  Future<void> _initializeCamera() async {
    try {
      print('🚀 멀티모달 세션 초기화 시작');
      
      // 사용 가능한 카메라 목록 가져오기
      final cameras = await availableCameras();
      print('📷 사용 가능한 모든 카메라:');
      for (int i = 0; i < cameras.length; i++) {
        print('   $i: ${cameras[i].name} (${cameras[i].lensDirection})');
      }
      
      _cameras = cameras;
      
      // 전면 카메라 우선 선택 (사용자 경험 최우선)
      final frontCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      final backCameras = cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();
      
      print('📷 전면 카메라 목록: ${frontCameras.map((c) => cameras.indexOf(c)).toList()}');
      print('📷 후면 카메라 목록: ${backCameras.map((c) => cameras.indexOf(c)).toList()}');
      
      // 전면 카메라 우선 선택 (사용자 경험 최우선)
      if (frontCameras.isNotEmpty) {
        _selectedCameraIndex = cameras.indexOf(frontCameras.first);
        print('📷 전면 카메라 선택됨: 인덱스 $_selectedCameraIndex (사용자 경험 최우선)');
      } else if (backCameras.isNotEmpty) {
        _selectedCameraIndex = cameras.indexOf(backCameras.first);
        print('📷 후면 카메라 선택됨: 인덱스 $_selectedCameraIndex (전면 카메라 없음)');
      } else {
        _selectedCameraIndex = 0;
        print('📷 기본 카메라 선택됨: 인덱스 $_selectedCameraIndex');
      }
      
      final selectedCamera = cameras[_selectedCameraIndex];
      print('📷 최종 선택된 카메라: ${selectedCamera.name} (${selectedCamera.lensDirection})');
      
      // 카메라 상세 정보 출력
      print('📷 카메라 상세 정보:');
      print('   - 이름: ${selectedCamera.name}');
      print('   - 방향: ${selectedCamera.lensDirection}');
      print('   - 인덱스: $_selectedCameraIndex');
      
      // 카메라 컨트롤러 초기화 (해상도를 low로 설정하여 왜곡 최소화)
      print('📷 카메라 컨트롤러 초기화: ${selectedCamera.name}');
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.low, // medium 대신 low 사용하여 왜곡 최소화
        enableAudio: false, // 오디오는 별도로 처리
        imageFormatGroup: ImageFormatGroup.bgra8888, // iOS에서 안정적인 포맷
      );
      
      await _cameraController!.initialize();
      
      // 카메라 정보 출력
      final value = _cameraController!.value;
      print('📷 카메라 비율: ${value.aspectRatio}');
      print('📷 카메라 방향: ${value.deviceOrientation}');
      print('📷 카메라 초기화됨: ${value.isInitialized}');
      
      setState(() {
        _isCameraInitialized = true;
      });
      
      print('✅ 카메라 초기화 완료: ${selectedCamera.name}');
      
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
      setState(() {
        _statusMessage = '카메라 초기화 실패: $e';
      });
    }
  }

  /// 오디오 매니저 초기화
  Future<void> _initializeAudioManager() async {
    try {
      final success = await _audioManager.initialize(
        onTextRecognized: (text) {
          print('🎤 텍스트 인식: $text');
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
          print('❌ 오디오 매니저 오류: $error');
        },
      );
      
      if (success) {
        print('✅ 오디오 매니저 초기화 완료');
      }
    } catch (e) {
      print('❌ 오디오 매니저 초기화 실패: $e');
    }
  }

  /// 세션 시작
  Future<void> _startSession() async {
    if (_isSessionActive) return;
    
    print('🚀 멀티모달 세션 시작');
    
    // EmotionProvider 세션 시작
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    emotionProvider.startSession();
    
    // 카메라 프리뷰 표시 활성화
    setState(() {
      _showCameraPreview = true;
    });
    
    // 카메라 스트림 시작
    await _startCameraStream();
    
    // STT 시작
    final sttSuccess = await _audioManager.startSTT();
    if (sttSuccess) {
      print('✅ STT 시작 성공 - 실시간 음성 인식 활성화');
      setState(() {
        _isListening = true;
      });
    } else {
      print('❌ STT 시작 실패 - 음성 인식 없이 진행');
    }
    
    // 30초 세션 타이머 시작
    _sessionTimer = Timer(const Duration(seconds: 30), () async {
      print('⏰ 30초 세션 타이머 완료 - 세션 종료');
      await _stopSession();
    });
    
    // 실시간 분석 타이머 시작 (5초마다)
    _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isSessionActive && mounted) {
        print('🔄 주기적 분석 실행 (${DateTime.now().second}초)');
        await _performMultimodalAnalysis();
      } else {
        print('⚠️ 주기적 분석 중단: 세션=${_isSessionActive}, mounted=$mounted');
        timer.cancel();
      }
    });
    
    setState(() {
      _isSessionActive = true;
      _statusMessage = '실시간 분석 시작... (30초 세션)';
    });
    
    print('✅ 세션 시작 완료 - 30초 동안 5초마다 분석 실행 (STT만 사용)');
  }

  /// 카메라 스트림 시작 (프레임 캡처용)
  Future<void> _startCameraStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    // 이미 스트리밍 중이면 중복 시작 방지
    if (_cameraController!.value.isStreamingImages) {
      print('⚠️ 카메라 스트림이 이미 실행 중입니다.');
      return;
    }
    
    try {
      print('📷 카메라 스트림 시작 (프레임 캡처용)');
      
      await _cameraController!.startImageStream((CameraImage image) {
        // 즉시 첫 프레임 캡처
        if (_lastAnalyzedTime == null) {
          _lastAnalyzedTime = DateTime.now();
          _captureFrameForAnalysis(image);
          print('📷 첫 프레임 캡처 완료');
        }
        // 이후 5초마다 프레임 캡처
        else {
          final now = DateTime.now();
          if (now.difference(_lastAnalyzedTime!).inSeconds >= 5) {
            _lastAnalyzedTime = now;
            _captureFrameForAnalysis(image);
            print('📷 주기적 프레임 캡처 완료');
          }
        }
      });
      
      print('✅ 카메라 스트림 시작 완료');
    } catch (e) {
      print('❌ 카메라 스트림 시작 실패: $e');
    }
  }

  /// 프레임 캡처 (분석용)
  void _captureFrameForAnalysis(CameraImage image) {
    if (!_isSessionActive || _isAnalyzing) return;
    
    try {
      print('📷 프레임 캡처: ${image.width} x ${image.height}');
      
      // CameraImage를 Base64로 변환
      final base64Image = _convertCameraImageToBase64(image);
      
      // EmotionProvider에 이미지 데이터 설정
      final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
      emotionProvider.setImageData(base64Image);
      
      print('✅ 프레임 캡처 완료 - 이미지 데이터 설정됨');
      
    } catch (e) {
      print('❌ 프레임 캡처 실패: $e');
    }
  }

  /// CameraImage를 Base64로 변환
  String _convertCameraImageToBase64(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      
      // 다양한 이미지 포맷 지원
      if (image.planes.length == 1) {
        // 단일 플레인 (예: BGRA, RGBA)
        print('📷 단일 플레인 이미지 처리: [32m[0m');
        return _convertSinglePlaneImage(image);
      } else if (image.planes.length == 3) {
        // YUV 포맷
        print('📷 YUV 이미지 처리');
        return _convertYUVImage(image);
      } else {
        print('⚠️ 지원하지 않는 이미지 포맷: ${image.planes.length} planes');
        return _createDummyImageBase64();
      }
      
    } catch (e) {
      print('❌ 이미지 변환 실패: $e');
      return _createDummyImageBase64();
    }
  }

  /// YUV 이미지 변환
  String _convertYUVImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    // 배열 크기 검사
    if (yPlane.length < width * height || 
        uPlane.length < (width * height) ~/ 4 || 
        vPlane.length < (width * height) ~/ 4) {
      print('⚠️ 이미지 데이터 크기가 부족합니다. Y:${yPlane.length}, U:${uPlane.length}, V:${vPlane.length}');
      return _createDummyImageBase64();
    }

    final outImg = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        
        // UV 인덱스 계산 (안전하게)
        final int uvY = (y / 2).floor();
        final int uvX = (x / 2).floor();
        final int uvIndex = uvY * uvRowStride + uvX * (uvPixelStride ?? 1);
        
        // 배열 범위 검사
        if (yIndex >= yPlane.length || uvIndex >= uPlane.length || uvIndex >= vPlane.length) {
          continue; // 이 픽셀은 건너뛰기
        }
        
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
    
    // JPEG로 인코딩
    final jpg = img.encodeJpg(outImg, quality: 85);
    return base64Encode(jpg);
  }

  /// 단일 플레인 이미지 변환 (BGRA, RGBA 등)
  String _convertSinglePlaneImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final bytes = image.planes[0].bytes;
    
    final outImg = img.Image(width: width, height: height);
    
    // BGRA 또는 RGBA 포맷 처리
    final bytesPerPixel = bytes.length ~/ (width * height);
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = (y * width + x) * bytesPerPixel;
        
        if (index + 3 < bytes.length) {
          int r, g, b, a;
          
          if (bytesPerPixel == 4) {
            // BGRA 또는 RGBA
            b = bytes[index];
            g = bytes[index + 1];
            r = bytes[index + 2];
            a = bytes[index + 3];
          } else if (bytesPerPixel == 3) {
            // BGR 또는 RGB
            b = bytes[index];
            g = bytes[index + 1];
            r = bytes[index + 2];
            a = 255;
          } else {
            // 그레이스케일
            r = g = b = bytes[index];
            a = 255;
          }
          
          outImg.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }
    
    // JPEG로 인코딩
    final jpg = img.encodeJpg(outImg, quality: 85);
    return base64Encode(jpg);
  }

  /// 더미 이미지 생성 (오류 시 사용)
  String _createDummyImageBase64() {
    try {
      // 1x1 픽셀의 회색 이미지 생성
      final dummyImg = img.Image(width: 1, height: 1);
      dummyImg.setPixelRgba(0, 0, 128, 128, 128, 255);
      final jpg = img.encodeJpg(dummyImg, quality: 85);
      return base64Encode(jpg);
    } catch (e) {
      print('❌ 더미 이미지 생성 실패: $e');
      return '';
    }
  }

  /// 세션 중지
  Future<void> _stopSession() async {
    print('🏁 멀티모달 세션 종료');
    
    // 세션 상태 즉시 변경
    setState(() {
      _isSessionActive = false;
      _isAnalyzing = false;
      _showCameraPreview = false;
    });
    
    // 모든 타이머 즉시 취소
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _textDebounceTimer?.cancel();
    _textDebounceTimer = null;
    
    // STT 중지
    await _audioManager.stopSTT();
    setState(() {
      _isListening = false;
    });
    
    // 카메라 스트림 중지
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
        print('📷 카메라 스트림 중지 완료');
      } catch (e) {
        print('❌ 카메라 스트림 중지 실패: $e');
      }
    }
    
    // EmotionProvider 세션 종료
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    final sessionResult = emotionProvider.endSession();
    
    setState(() {
      _statusMessage = '세션 종료됨';
      _analysisSummary = sessionResult.feedback;
    });
    
    print('📊 세션 결과: ${sessionResult.feedback}');
    print('📈 분석 품질: ${(emotionProvider.currentAnalysisQuality * 100).toStringAsFixed(1)}%');
    print('📊 사용된 모달리티: ${emotionProvider.availableModalitiesInfo}');

    // 세션 중지 후 분석 대기 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AnalysisPendingScreen(sessionData: _sessionData),
        ),
      );
    }
  }

  /// 세션 일시정지
  void _pauseSession() {
    if (_isSessionActive) {
      _analysisTimer?.cancel();
      _sessionTimer?.cancel();
      
      // 카메라 스트림 일시정지
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        try {
          _cameraController!.stopImageStream();
          print('📷 카메라 스트림 일시정지');
        } catch (e) {
          print('❌ 카메라 스트림 일시정지 실패: $e');
        }
      }
      
      setState(() {
        _statusMessage = '세션 일시정지됨';
      });
    }
  }

  /// 세션 재개
  void _resumeSession() {
    if (_isSessionActive) {
      // 카메라 스트림 재시작
      _startCameraStream();
      
      // 분석 타이머 재시작
      _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (_isSessionActive) {
          await _performMultimodalAnalysis();
        } else {
          timer.cancel();
        }
      });
      
      setState(() {
        _statusMessage = '실시간 분석 재개... (${_sessionData.length}회 완료)';
      });
    }
  }

  /// 멀티모달 분석 수행
  Future<void> _performMultimodalAnalysis() async {
    // 세션이 비활성화되었거나 이미 분석 중이면 중단
    if (!_isSessionActive || _isAnalyzing) {
      print('⚠️ 분석 중단: 세션=${_isSessionActive}, 분석중=${_isAnalyzing}');
      return;
    }
    
    // mounted 체크 추가
    if (!mounted) {
      print('⚠️ 위젯이 dispose됨, 분석 취소');
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _statusMessage = '새로운 분석 중...';
    });
    
    try {
      print('🔍 [Session] 멀티모달 분석 실행 시작');
      
      // 세션 상태 재확인
      if (!_isSessionActive) {
        print('⚠️ 세션이 중단됨, 분석 취소');
        return;
      }
      
      // EmotionProvider에서 현재 데이터 가져오기
      final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
      
      // 이미지 데이터는 이미 스트림에서 캡처되어 있음
      final imageData = emotionProvider.currentImageData;
      final textData = emotionProvider.currentTextData;
      
      print('📊 [Session] 분석할 데이터 상태:');
      print('   - 이미지 데이터: ${imageData != null ? "있음 (${imageData.length} bytes)" : "없음"}');
      print('   - 텍스트 데이터: ${textData != null ? "있음: $textData" : "없음"}');
      print('   - STT 인식 텍스트: ${_recognizedText.isNotEmpty ? "있음: $_recognizedText" : "없음"}');
      
      // STT 텍스트가 있으면 EmotionProvider에 설정
      if (_recognizedText.isNotEmpty && textData != _recognizedText) {
        emotionProvider.setTextData(_recognizedText);
        print('📝 [Session] STT 텍스트 데이터 설정: $_recognizedText');
      }
      
      // 세션 상태 최종 확인
      if (!_isSessionActive) {
        print('⚠️ 세션이 중단됨, 분석 취소');
        return;
      }
      
      // 멀티모달 분석 실행
      print('🚀 [Session] EmotionProvider 멀티모달 분석 호출');
      final result = await emotionProvider.performMultimodalAnalysis();
      
      // 세션 상태 재확인
      if (!mounted || !_isSessionActive) {
        print('⚠️ 세션이 중단됨, 결과 처리 취소');
        return;
      }
      
      if (result != null) {
        print('✅ [Session] 멀티모달 분석 완료: ${result.emotion} (${((result.confidence ?? 0.0) * 100).toStringAsFixed(1)}%)');
        // 세션 데이터에 결과 추가
        _sessionData.add(result);
        print('📊 [Session] 세션 데이터 포인트 추가됨: 총 ${_sessionData.length}개');
        
        // 분석 완료 후 상태 메시지 업데이트
        setState(() {
          _currentEmotion = result.emotion ?? 'neutral';
          _currentConfidence = result.confidence ?? 0.0;
          _lastAnalyzedTime = DateTime.now();
          _statusMessage = '실시간 분석 중... (${_sessionData.length}회 완료)';
        });
        
        // 감정 변화 시 애니메이션 트리거
        _emotionController.forward().then((_) {
          _emotionController.reverse();
        });
      }
      
    } catch (e) {
      print('❌ [Session] 멀티모달 분석 실패: $e');
      if (mounted && _isSessionActive) {
        setState(() {
          _statusMessage = '분석 실패 - 재시도 중...';
        });
      }
    } finally {
      // mounted 체크 후 setState 호출
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        print('🏁 [Session] 분석 상태 해제됨');
      }
    }
  }

  /// 인식된 텍스트 처리
  void _processRecognizedText(String text) {
    if (text.isEmpty) return;
    
    print('📝 [Session] STT 텍스트 처리: "$text"');
    
    setState(() {
      _recognizedText = text;
    });
    
    // EmotionProvider에 텍스트 데이터 전달
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    emotionProvider.setTextData(text);
    print('📝 [Session] 텍스트 데이터 수집: $text');
    
    // 텍스트 디바운스
    _textDebounceTimer?.cancel();
    _textDebounceTimer = Timer(const Duration(seconds: 1), () {
      if (_isSessionActive) {
        print('🔄 [Session] STT 텍스트로 인한 분석 실행');
        _performMultimodalAnalysis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 3D 배경 레이어
            _build3DBackground(),
            
            // 파티클 시스템
            _buildParticleSystem(),
            
            // 메인 컨텐츠
            Column(
              children: [
                // 상단 상태바
                _buildTopStatusBar(),
                
                const Spacer(),
                
                // 중앙 감정 아이콘 (세션 활성화 시)
                if (_isSessionActive) _buildEmotionCenter(),
                
                // 중앙 가이드 (세션 비활성화 시)
                if (!_isSessionActive) _buildCenterGuide(),
                
                const Spacer(),
                
                // 하단 컨트롤
                _buildBottomControls(),
              ],
            ),
            
            // 우측 하단 작은 카메라 프리뷰 (원형)
            if (_showCameraPreview && _isCameraInitialized && _cameraController != null)
              _buildSmallCameraPreview(),
          ],
        ),
      ),
    );
  }

  /// 3D 배경 위젯 (이제 solid black)
  Widget _build3DBackground() {
    return Container(
      color: Colors.black,
    );
  }

  /// 파티클 시스템 위젯
  Widget _buildParticleSystem() {
    return ParticleSystem(
      particles: _particles,
      animation: _particleController,
      particleColor: _getEmotionColor(_currentEmotion),
    );
  }

  /// 중앙 감정 아이콘
  Widget _buildEmotionCenter() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 감정 아이콘
          HoloSphere(
            color: _getEmotionColor(_currentEmotion),
            size: 180,
            controller: _emotionController,
          ),
          const SizedBox(height: 24),
          
          // 감정 텍스트
          Text(
            _getEmotionText(_currentEmotion),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 신뢰도 표시
          Text(
            '${(_currentConfidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 감정 텍스트 가져오기
  String _getEmotionText(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return '기쁨 😊';
      case 'sad':
      case 'sadness':
        return '슬픔 😢';
      case 'angry':
      case 'anger':
        return '분노 😠';
      case 'fear':
        return '두려움 😨';
      case 'surprise':
        return '놀람 😲';
      case 'disgust':
        return '혐오 🤢';
      default:
        return '중립 😐';
    }
  }

  /// 작은 카메라 프리뷰 위젯
  Widget _buildSmallCameraPreview() {
    if (_cameraController == null || !_isCameraInitialized) {
      return const SizedBox.shrink();
    }

    final selectedCamera = _cameras[_selectedCameraIndex];
    final isFrontCamera = selectedCamera.lensDirection == CameraLensDirection.front;

    return Positioned(
      right: 20,
      bottom: 120,
      child: Container(
        width: 80, // 작은 크기로 조정
        height: 80, // 작은 크기로 조정
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: _buildOptimizedCameraPreview(isFrontCamera),
        ),
      ),
    );
  }

  /// 최적화된 카메라 프리뷰 (왜곡 최소화)
  Widget _buildOptimizedCameraPreview(bool isFrontCamera) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    // 강력한 중앙 크롭으로 왜곡 최소화
    Widget cameraWidget = ClipRect(
      child: Align(
        alignment: Alignment.center,
        widthFactor: 0.4, // 중앙 40%만 사용
        heightFactor: 0.4,
        child: AspectRatio(
          aspectRatio: 1.0, // 1:1 비율로 강제
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
    
    // 전면 카메라일 때만 미러링 적용 (좌우반전)
    if (isFrontCamera) {
      cameraWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: cameraWidget,
      );
    }
    
    return cameraWidget;
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(
        color: Colors.grey[800],
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    final selectedCamera = _cameras[_selectedCameraIndex];
    final isFrontCamera = selectedCamera.lensDirection == CameraLensDirection.front;
    
    // 중앙 크롭 + 비율 유지로 왜곡 최소화
    Widget cameraWidget = ClipRect(
      child: Align(
        alignment: Alignment.center,
        widthFactor: 0.6, // 중앙 60%만 사용 (왜곡이 심한 가장자리 제거)
        heightFactor: 0.6,
        child: AspectRatio(
          aspectRatio: _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
    
    // 전면 카메라일 때만 미러링 적용
    if (isFrontCamera) {
      cameraWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: cameraWidget,
      );
    }
    
    return cameraWidget;
  }

  Widget _buildTopStatusBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 상태 인디케이터
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isSessionActive 
                    ? (_isAnalyzing ? Colors.blue : Colors.green)
                    : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              
              // 상태 메시지
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // STT 상태 표시
              if (_isSessionActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isListening ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        color: _isListening ? Colors.green : Colors.grey,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isListening ? '음성인식' : '대기',
                        style: TextStyle(
                          color: _isListening ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          // 인식된 텍스트 표시
          if (_isSessionActive && _recognizedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.text_fields,
                    color: Colors.blue,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCenterGuide() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          
          // 제목
          const Text(
            '멀티모달 감정 분석',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // 설명
          Text(
            '30초마다 자동으로 감정을 분석합니다\n자연스럽게 대화하시면 됩니다',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 세션 시작/중지 버튼
          GestureDetector(
            onTap: _isSessionActive ? _stopSession : _startSession,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isSessionActive 
                    ? [Colors.red, Colors.red.shade700]
                    : [Colors.green, Colors.green.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isSessionActive ? Colors.red : Colors.green).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _isSessionActive ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 파티클 생성 (배경용, 중앙 100px 이내는 생성 안 함)
  void _generateParticles() {
    _particles.clear();
    final center = Offset(200, 400); // 대략 화면 중앙
    for (int i = 0; i < 15; i++) {
      double x, y;
      do {
        x = _random.nextDouble() * 400;
        y = _random.nextDouble() * 800;
      } while ((Offset(x, y) - center).distance < 100);
      _particles.add(Particle(
        x: x,
        y: y,
        speed: 0.1 + _random.nextDouble() * 0.2,
        size: 1.0 + _random.nextDouble() * 1.5,
        opacity: 0.08 + _random.nextDouble() * 0.1,
      ));
    }
  }

  /// 감정에 따른 색상 가져오기
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.yellow;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      default:
        return Colors.white;
    }
  }
}

/// 파티클 클래스
class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double angle;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  }) : angle = 0.0;

  void update(double deltaTime) {
    angle += speed * deltaTime;
    y -= speed * deltaTime * 5; // 더 느리게
    if (y < -20) {
      y = 820;
      x = math.Random().nextDouble() * 400;
    }
  }
}

/// 파티클 시스템 위젯
class ParticleSystem extends StatelessWidget {
  final List<Particle> particles;
  final Animation<double> animation;
  final Color particleColor;

  const ParticleSystem({
    super.key,
    required this.particles,
    required this.animation,
    required this.particleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles,
            particleColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// 파티클 그리기
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color particleColor;

  ParticlePainter(this.particles, this.particleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      particle.update(0.016); // 60fps 기준
      
      paint.color = particleColor.withOpacity(particle.opacity);
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 감정 아이콘 위젯
class EmotionIcon extends StatelessWidget {
  final String emotion;
  final Animation<double> animation;
  final double confidence;

  const EmotionIcon({
    super.key,
    required this.emotion,
    required this.animation,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (animation.value * 0.2),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getEmotionColor(emotion).withOpacity(0.8),
                  _getEmotionColor(emotion).withOpacity(0.3),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _getEmotionColor(emotion).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _getEmotionIcon(emotion),
              color: Colors.white,
              size: 60,
            ),
          ),
        );
      },
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.yellow;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.purple;
      case 'surprise':
        return Colors.orange;
      case 'disgust':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'sadness':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
        return Icons.sentiment_dissatisfied;
      case 'surprise':
        return Icons.sentiment_satisfied_alt;
      case 'disgust':
        return Icons.sentiment_neutral;
      default:
        return Icons.psychology;
    }
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
    final barWidth = 4.0;
    final spacing = 2.0;
    final maxHeight = 20.0;
    final minHeight = 3.0;
    final cornerRadius = const Radius.circular(2.0);

    smoothedSoundLevel = smoothedSoundLevel * 0.3 + soundLevel * 0.7;

    for (int i = 0; i < barCount; i++) {
      final randomFactor = 0.8 + (i % 3) * 0.2;
      final barHeight = (smoothedSoundLevel * maxHeight * randomFactor).clamp(minHeight, maxHeight);
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

/// SF 홀로그램 구체 위젯
class HoloSphere extends StatefulWidget {
  final Color color;
  final double size;
  final AnimationController controller;

  const HoloSphere({
    super.key,
    required this.color,
    required this.size,
    required this.controller,
  });

  @override
  State<HoloSphere> createState() => _HoloSphereState();
}

class _HoloSphereState extends State<HoloSphere> {
  late List<_EnergyLine> _lines;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _lines = List.generate(7, (i) => _EnergyLine(widget.size, _random));
    _particles = List.generate(30, (i) => _Particle(widget.size, _random));
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GlowSpherePainter(widget.color),
          ),
          // Energy lines
          ..._lines.map((line) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _EnergyLinePainter(line, widget.color, widget.controller.value),
              )),
          // Particles
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ParticleSpherePainter(_particles, widget.color, widget.controller.value),
          ),
          // Core glow
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CoreGlowPainter(widget.color),
          ),
        ],
      ),
    );
  }
}

class _GlowSpherePainter extends CustomPainter {
  final Color color;
  _GlowSpherePainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.7),
          color.withOpacity(0.5),
          Colors.blueAccent.withOpacity(0.18),
          Colors.transparent
        ],
        stops: [0.0, 0.4, 0.8, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width/2));
    canvas.drawCircle(center, size.width/2, paint);
    // 외곽 블루/퍼플 글로우
    final outer = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.blueAccent.withOpacity(0.18),
          Colors.purpleAccent.withOpacity(0.12),
          Colors.transparent
        ],
        stops: [0.7, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width/2));
    canvas.drawCircle(center, size.width/2, outer);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoreGlowPainter extends CustomPainter {
  final Color color;
  _CoreGlowPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.98),
          color.withOpacity(0.4),
          Colors.transparent
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width/5));
    canvas.drawCircle(center, size.width/5, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnergyLine {
  final double size;
  final List<double> noiseOffsets;
  final double baseRadius;
  final double speed;
  _EnergyLine(this.size, math.Random random)
      : noiseOffsets = List.generate(32, (_) => random.nextDouble() * 2 * math.pi),
        baseRadius = size/2 * (0.7 + random.nextDouble()*0.2),
        speed = 0.5 + random.nextDouble();
}

class _EnergyLinePainter extends CustomPainter {
  final _EnergyLine line;
  final Color color;
  final double t;
  _EnergyLinePainter(this.line, this.color, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final path = Path();
    for (int i = 0; i <= line.noiseOffsets.length; i++) {
      final angle = (i/line.noiseOffsets.length) * 2 * math.pi;
      final noise = math.sin(angle*3 + t*2*math.pi*line.speed + line.noiseOffsets[i%line.noiseOffsets.length]);
      final r = line.baseRadius + noise * 12;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    // 여러 컬러로 레이어링
    final colors = [color.withOpacity(0.22)] + getSfHighlightColors(color).map((c) => c.withOpacity(0.10)).toList();
    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - i*0.5;
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Particle {
  double angle;
  double radius;
  double speed;
  double size;
  double opacity;
  _Particle(double sphereSize, math.Random random)
      : angle = random.nextDouble() * 2 * math.pi,
        radius = sphereSize/2 * (0.5 + random.nextDouble()*0.4),
        speed = 0.2 + random.nextDouble()*0.8,
        size = 1.5 + random.nextDouble()*2.5,
        opacity = 0.3 + random.nextDouble()*0.7;
}

class _ParticleSpherePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  final double t;
  _ParticleSpherePainter(this.particles, this.color, this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final highlightColors = getSfHighlightColors(color);
    for (final p in particles) {
      final angle = p.angle + t * 2 * math.pi * p.speed;
      final x = center.dx + p.radius * math.cos(angle);
      final y = center.dy + p.radius * math.sin(angle);
      // 여러 색상, 크기, 투명도
      for (int i = 0; i < highlightColors.length; i++) {
        final paint = Paint()
          ..color = highlightColors[i].withOpacity(p.opacity * (0.7 - i*0.15))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 + i*0.5);
        canvas.drawCircle(Offset(x, y), p.size * (1.0 - i*0.2), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 