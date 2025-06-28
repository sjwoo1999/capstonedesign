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
  
  // UI 상태
  String _statusMessage = '세션을 시작하세요';
  String _analysisSummary = '';

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
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.medium,
          enableAudio: false, // 오디오는 AudioManager에서 처리
        );
        
        await _cameraController!.initialize();
        
        setState(() {
          _isCameraInitialized = true;
        });
        
        print('✅ 카메라 초기화 완료');
      }
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
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
    
    final emotionProvider = Provider.of<EmotionProvider>(context, listen: false);
    emotionProvider.startSession();
    
    // 카메라 스트림 시작
    if (_cameraController != null && _isCameraInitialized) {
      await _cameraController!.startImageStream((image) {
        // 이미지 스트림 처리 (실제로는 주기적으로 캡처)
      });
    }
    
    // 오디오 녹음 시작
    await _audioManager.startRecording();
    
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
      _statusMessage = '실시간 멀티모달 분석 중...';
    });
  }

  /// 세션 중지
  Future<void> _stopSession() async {
    if (!_isSessionActive) return;
    
    print('🏁 멀티모달 세션 종료');
    
    _analysisTimer?.cancel();
    _textDebounceTimer?.cancel();
    
    // 카메라 스트림 중지
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
    }
    
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
      setState(() {
        _statusMessage = '세션 일시정지됨';
      });
    }
  }

  /// 세션 재개
  void _resumeSession() {
    if (_isSessionActive) {
      _analysisTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_isSessionActive) {
          _performMultimodalAnalysis();
        } else {
          timer.cancel();
        }
      });
      setState(() {
        _statusMessage = '실시간 멀티모달 분석 중...';
      });
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
      
      // 이미지 캡처
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        try {
          final image = await _cameraController!.takePicture();
          final bytes = await File(image.path).readAsBytes();
          imageData = base64Encode(bytes);
          print('📷 이미지 캡처: ${imageData.length} bytes');
        } catch (e) {
          print('❌ 이미지 캡처 실패: $e');
        }
      }
      
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '멀티모달 감정 분석',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 상태 표시 영역
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_analysisSummary.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _analysisSummary,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          
          // 카메라 프리뷰
          if (_isCameraInitialized && _cameraController != null)
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          
          // 분석 결과 표시
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnalysisCard(
                  '감정',
                  _currentEmotion,
                  Icons.emoji_emotions,
                  Colors.blue,
                ),
                _buildAnalysisCard(
                  '신뢰도',
                  '${(_currentConfidence * 100).toStringAsFixed(1)}%',
                  Icons.psychology,
                  Colors.green,
                ),
                _buildAnalysisCard(
                  '데이터',
                  '${_sessionData.length}개',
                  Icons.analytics,
                  Colors.orange,
                ),
              ],
            ),
          ),
          
          // 음성 파형 표시
          if (_isListening)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomPaint(
                painter: SoundWavePainter(_currentSoundLevel),
                size: const Size(double.infinity, 60),
              ),
            ),
          
          // 인식된 텍스트
          if (_recognizedText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '인식된 텍스트: $_recognizedText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // 컨트롤 버튼
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSessionActive ? _stopSession : _startSession,
                  icon: Icon(_isSessionActive ? Icons.stop : Icons.play_arrow),
                  label: Text(_isSessionActive ? '중지' : '시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSessionActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                if (_isSessionActive)
                  ElevatedButton.icon(
                    onPressed: _performMultimodalAnalysis,
                    icon: const Icon(Icons.analytics),
                    label: const Text('분석'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
    final barWidth = 8.0;
    final spacing = 4.0;
    final maxHeight = 20.0;
    final minHeight = 5.0;
    final cornerRadius = const Radius.circular(4.0);

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