import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/emotion_provider.dart';
import '../../services/audio_manager.dart';
import '../../models/emotion_data_point.dart';
import '../../models/multimodal_data_point.dart';
import '../../theme/bemore_theme.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

/// 멀티모달 감정 분석 세션 화면
/// 영상, 음성, 텍스트 세 가지 모달리티를 통합하여 실시간 감정 분석
class MultimodalSessionScreen extends StatefulWidget {
  const MultimodalSessionScreen({super.key});

  @override
  State<MultimodalSessionScreen> createState() => _MultimodalSessionScreenState();
}

class _MultimodalSessionScreenState extends State<MultimodalSessionScreen> 
    with WidgetsBindingObserver {
  
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
  final List<MultimodalDataPoint> _multimodalData = [];
  
  // 타이머
  Timer? _analysisTimer;
  Timer? _textDebounceTimer;
  Timer? _imageCaptureTimer;
  
  // UI 상태
  String _statusMessage = '세션을 시작하세요';
  String _analysisSummary = '';
  bool _showCameraPreview = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopSession();
    _cameraController?.dispose();
    _audioManager.dispose();
    _analysisTimer?.cancel();
    _textDebounceTimer?.cancel();
    _imageCaptureTimer?.cancel();
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
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // 전면 카메라 우선 선택
        _selectedCameraIndex = _cameras.indexWhere((camera) => 
          camera.lensDirection == CameraLensDirection.front) ?? 0;
        
        await _initializeCameraController();
        print('✅ 카메라 초기화 완료: ${_cameras[_selectedCameraIndex].name}');
      }
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
    }
  }

  /// 카메라 컨트롤러 초기화
  Future<void> _initializeCameraController() async {
    try {
      _cameraController?.dispose();
      
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium, // medium으로 변경하여 성능 최적화
        enableAudio: false, // 오디오는 AudioManager에서 처리
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print('❌ 카메라 컨트롤러 초기화 실패: $e');
    }
  }

  /// 카메라 전환
  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCameraController();
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
    
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    emotionProvider.startSession();
    
    // 카메라 프리뷰 시작
    if (_cameraController != null && _isCameraInitialized) {
      setState(() {
        _showCameraPreview = true;
      });
    }
    
    // 오디오 녹음 시작
    await _audioManager.startRecording();
    
    // 이미지 캡처 타이머 시작 (3초마다)
    _imageCaptureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isSessionActive && !_isAnalyzing) {
        _captureImageForAnalysis();
      }
    });
    
    // 실시간 분석 타이머 시작
    _analysisTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_isSessionActive) {
        _performMultimodalAnalysis();
      } else {
        timer.cancel();
      }
    });
    
    setState(() {
      _isSessionActive = true;
      _statusMessage = '실시간 분석 중...';
    });
  }

  /// 세션 중지
  Future<void> _stopSession() async {
    if (!_isSessionActive) return;
    
    print('🏁 멀티모달 세션 종료');
    
    _analysisTimer?.cancel();
    _textDebounceTimer?.cancel();
    _imageCaptureTimer?.cancel();
    
    // 카메라 프리뷰 중지
    setState(() {
      _showCameraPreview = false;
    });
    
    // 오디오 녹음 중지
    await _audioManager.stopRecording();
    
    // EmotionProvider 세션 종료
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    final sessionResult = emotionProvider.endSession();
    
    setState(() {
      _isSessionActive = false;
      _statusMessage = '세션 종료됨';
      _analysisSummary = sessionResult.feedback;
    });
    
    print('📊 세션 결과: ${sessionResult.feedback}');
    print('📈 분석 품질: ${(emotionProvider.currentAnalysisQuality * 100).toStringAsFixed(1)}%');
    print('📊 사용된 모달리티: ${emotionProvider.availableModalitiesInfo}');
  }

  /// 세션 일시정지
  void _pauseSession() {
    if (_isSessionActive) {
      _analysisTimer?.cancel();
      _imageCaptureTimer?.cancel();
      setState(() {
        _statusMessage = '세션 일시정지됨';
      });
    }
  }

  /// 세션 재개
  void _resumeSession() {
    if (_isSessionActive) {
      _imageCaptureTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_isSessionActive && !_isAnalyzing) {
          _captureImageForAnalysis();
        }
      });
      
      _analysisTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_isSessionActive) {
          _performMultimodalAnalysis();
        } else {
          timer.cancel();
        }
      });
      
      setState(() {
        _statusMessage = '실시간 분석 중...';
      });
    }
  }

  /// 이미지 캡처 (분석용)
  Future<String?> _captureImageForAnalysis() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      print('📷 이미지 캡처: ${base64Image.length} bytes');
      return base64Image;
    } catch (e) {
      print('❌ 이미지 캡처 실패: $e');
      return null;
    }
  }

  /// 멀티모달 분석 실행
  Future<void> _performMultimodalAnalysis() async {
    if (_isAnalyzing) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    
    try {
      print('🔍 멀티모달 분석 실행');
      
      final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
      
      // 현재 데이터 수집
      String? imageData;
      String? audioData;
      String? textData = _recognizedText.isNotEmpty ? _recognizedText : null;
      
      // 이미지 데이터 (캐시된 것 사용)
      imageData = await _captureImageForAnalysis();
      
      // 오디오 데이터 수집
      if (_audioManager.isRecording) {
        try {
          audioData = await _audioManager.getCurrentAudioData();
          print('🎤 오디오 데이터: ${audioData?.length ?? 0} bytes');
        } catch (e) {
          print('❌ 오디오 데이터 수집 실패: $e');
        }
      }
      
      // EmotionProvider에 데이터 설정
      emotionProvider.setImageData(imageData);
      emotionProvider.setAudioData(audioData);
      emotionProvider.setTextData(textData);
      
      // 멀티모달 분석 실행
      final dataPoint = await emotionProvider.performMultimodalAnalysis(
        sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'sound_level': _currentSoundLevel,
        },
      );
      
      if (dataPoint != null) {
        _sessionData.add(dataPoint);
        if (dataPoint.hasMultimodalData) {
          _multimodalData.add(dataPoint.multimodalData!);
        }
        
        setState(() {
          _currentEmotion = dataPoint.emotion ?? 'neutral';
          _currentConfidence = dataPoint.confidence ?? 0.0;
        });
        
        print('✅ 멀티모달 분석 완료: ${dataPoint.emotion} (${(dataPoint.confidence ?? 0.0 * 100).toStringAsFixed(1)}%)');
      }
      
    } catch (e) {
      print('❌ 멀티모달 분석 실패: $e');
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  /// 인식된 텍스트 처리
  void _processRecognizedText(String text) {
    if (text.isEmpty) return;
    
    setState(() {
      _recognizedText = text;
    });
    
    // 텍스트 디바운스
    _textDebounceTimer?.cancel();
    _textDebounceTimer = Timer(const Duration(seconds: 1), () {
      if (_isSessionActive) {
        _performMultimodalAnalysis();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 카메라 프리뷰 (전체 화면)
          if (_showCameraPreview && _isCameraInitialized && _cameraController != null)
            _buildCameraPreview(),
          
          // 오버레이 UI
          _buildOverlayUI(),
          
          // 하단 컨트롤 영역
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
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

  Widget _buildOverlayUI() {
    return SafeArea(
      child: Column(
        children: [
          // 상단 상태 바
          _buildTopStatusBar(),
          
          const Spacer(),
          
          // 중앙 분석 결과
          if (_isSessionActive) _buildAnalysisResults(),
          
          const Spacer(),
          
          // 음성 파형 (있는 경우)
          if (_isListening && _currentSoundLevel > 0) _buildSoundWave(),
        ],
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // 상태 인디케이터
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isSessionActive 
                ? (_isAnalyzing ? Colors.blue : Colors.green)
                : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          
          // 상태 메시지
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // 카메라 전환 버튼
          if (_isCameraInitialized && _cameras.length > 1)
            GestureDetector(
              onTap: _switchCamera,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // 감정 결과
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildResultItem(
                icon: Icons.emoji_emotions,
                label: '감정',
                value: _currentEmotion,
                color: Colors.blue,
              ),
              _buildResultItem(
                icon: Icons.psychology,
                label: '신뢰도',
                value: '${(_currentConfidence * 100).toStringAsFixed(1)}%',
                color: Colors.green,
              ),
              _buildResultItem(
                icon: Icons.analytics,
                label: '데이터',
                value: '${_sessionData.length}개',
                color: Colors.orange,
              ),
            ],
          ),
          
          // 인식된 텍스트
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mic,
                        color: Colors.white.withOpacity(0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '인식된 텍스트',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _recognizedText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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

  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSoundWave() {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: CustomPaint(
        painter: SoundWavePainter(_currentSoundLevel),
        size: const Size(double.infinity, 30),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 세션 시작/중지 버튼
            Expanded(
              child: GestureDetector(
                onTap: _isSessionActive ? _stopSession : _startSession,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isSessionActive 
                        ? [Colors.red, Colors.red.shade700]
                        : [Colors.green, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (_isSessionActive ? Colors.red : Colors.green).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSessionActive ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSessionActive ? '중지' : '시작',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // 수동 분석 버튼
            if (_isSessionActive) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _performMultimodalAnalysis,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '분석',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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