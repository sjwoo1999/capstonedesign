import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
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
import 'package:speech_to_text/speech_to_text.dart' as stt;


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
  
  // 카메라 관련
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = false;
  bool _hasMicPermission = false;
  String _cameraError = '';

  // 오디오 관련
  stt.SpeechToText? _speechToText;
  bool _isListening = false;
  String _lastWords = '';

  // 대화 관련
  DateTime? _conversationStartTime;
  DateTime? _conversationEndTime;
  List<String> _conversationNotes = [];
  DateTime _lastAnalyzedTime = DateTime.now();
  final List<EmotionDataPoint> _sessionData = [];

  @override
  void initState() {
    super.initState();
    print('🚀 실시간 대화 화면 초기화 시작');
    _checkPermissions();
    
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
    _cameraController?.dispose();
    _stopVoiceAnalysis();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await _checkCameraPermission();
    await _checkMicPermission();

    // 시뮬레이터에서는 권한이 없어도 카메라 초기화를 시도
    if (_hasCameraPermission || _isSimulator()) {
      _initializeCamera();
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
      } else if (status.isDenied) {
        print('❌ 카메라 권한 거부됨, 요청 시작');
        await Permission.camera.request();
        setState(() {}); // Re-check permissions after request
      } else if (status.isPermanentlyDenied) {
        print('🚫 카메라 권한 영구 거부됨');
        setState(() {
          _hasCameraPermission = false;
        });
      }
    } catch (e) {
      print('❌ 권한 상태 확인 중 오류: $e');
    }
  }

  Future<void> _checkMicPermission() async {
    try {
      print('🔍 마이크 권한 상태 확인');
      final status = await Permission.microphone.status;
      print('🎤 현재 마이크 권한 상태: $status');

      if (status.isGranted) {
        print('✅ 마이크 권한 이미 허용됨');
        setState(() {
          _hasMicPermission = true;
        });
      } else if (status.isDenied) {
        print('❌ 마이크 권한 거부됨, 요청 시작');
        await Permission.microphone.request();
        setState(() {}); // Re-check permissions after request
      } else if (status.isPermanentlyDenied) {
        print('🚫 마이크 권한 영구 거부됨');
        setState(() {
          _hasMicPermission = false;
        });
      }
    } catch (e) {
      print('❌ 마이크 권한 확인 중 오류: $e');
    }
  }

  void _retryPermissionRequest() {
    print('🔄 권한 요청 재시도');
    setState(() {
      _hasCameraPermission = false;
      _hasMicPermission = false;
      _cameraError = '';
    });
    _checkPermissions();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text(
          '실시간 대화를 위해 카메라 접근이 필요합니다.\n'
          '설정에서 카메라 권한을 허용해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text(
          '실시간 대화를 위해 카메라 접근이 필요합니다.\n'
          '권한을 허용하지 않으면 대화 기능을 사용할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkPermissions();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('📱 사용 가능한 카메라가 없습니다 (시뮬레이터)');
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
        setState(() {
          _cameraError = '전면 카메라를 찾을 수 없습니다.';
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
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

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _conversationState = ConversationState.ready;
        });
      }
    } catch (e) {
      print('❌ 카메라 초기화 실패: $e');
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
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카메라가 준비되지 않았습니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    if (_conversationTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대화 주제를 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _conversationState = ConversationState.talking;
      _conversationStartTime = DateTime.now();
    });
    
    print('🎤 대화 시작: $_conversationTopic');
    
    // 실시간 감정 분석 시뮬레이션 시작
    _startRealTimeAnalysis();
  }

  void _endConversation() async {
    setState(() {
      _conversationState = ConversationState.ending;
      _conversationEndTime = DateTime.now();
    });
    
    _cameraController?.stopImageStream();
    await _stopVoiceAnalysis();
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
    _startImageAnalysis();
    _startVoiceAnalysis();
  }

  void _startImageAnalysis() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    // 이미지 스트림 시작
    _cameraController!.startImageStream((CameraImage cameraImage) async {
      // 3초에 한 번씩만 이미지를 처리하도록 제어
      final now = DateTime.now();
      if (now.difference(_lastAnalyzedTime) < const Duration(seconds: 3)) {
        return;
      }
      _lastAnalyzedTime = now;

      try {
        // 1. CameraImage를 일반 이미지(JPEG)로 변환
        final image = _convertCameraImage(cameraImage);
        if (image == null) return;

        // 2. 이미지를 Base64 문자열로 인코딩
        final base64Image = base64Encode(img.encodeJpg(image));

        // 3. API 서비스로 전송하여 분석 요청
        final apiService = EmotionAPIService();
        print('🚀 API 요청 전송 시작...');
        final result = await apiService.sendImageForAnalysis(base64Image);
        print('✅ API 응답 수신: $result');

        // 4. 응답 결과를 EmotionDataPoint 모델로 변환
        final newDataPoint = EmotionDataPoint(
          timestamp: DateTime.now(),
          valence: result['vad']['valence']?.toDouble() ?? 0.0,
          arousal: result['vad']['arousal']?.toDouble() ?? 0.0,
          dominance: result['vad']['dominance']?.toDouble() ?? 0.0,
        );
        
        _sessionData.add(newDataPoint);
        print('📊 VAD 데이터 수신: ${jsonEncode(newDataPoint.toJson())}');

      } catch (e) {
        print('❌ 실시간 분석 API 호출 실패: $e');
      }
    });
  }

  Future<void> _startVoiceAnalysis() async {
    if (!_hasMicPermission && !_isSimulator()) {
      print('🎤 마이크 권한이 없어 음성 분석을 시작할 수 없습니다.');
      return;
    }
    try {
      print('🎤 음성 인식 시작...');
      _speechToText = stt.SpeechToText();
      final available = await _speechToText!.initialize();
      if (available) {
        _isListening = true;
        await _speechToText!.listen(
          onResult: (result) {
            print('🎧 음성 인식 결과: ${result.recognizedWords}');
            setState(() {
              _lastWords = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'ko_KR',
        );
      } else {
        print('❌ 음성 인식을 사용할 수 없습니다.');
        if (_isSimulator()) {
          print('📱 시뮬레이터에서는 음성 인식이 제한될 수 있습니다.');
        }
      }
    } catch (e) {
      print('❌ 음성 인식 시작 실패: $e');
      if (_isSimulator()) {
        print('📱 시뮬레이터에서는 음성 인식이 제한될 수 있습니다.');
      }
    }
  }

  Future<void> _stopVoiceAnalysis() async {
    try {
      if (_speechToText != null && _isListening) {
        await _speechToText!.stop();
        _isListening = false;
        print('🔇 음성 인식 중지');
      }
    } catch (e) {
      print('❌ 음성 인식 중지 실패: $e');
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
          // 1. 카메라 미리보기 (전체 배경)
          Positioned.fill(child: _buildCameraPreview()),

          // 2. 상단 UI (뒤로가기, 대화 시간)
          _buildTopBar(),
          
          // 3. 하단 컨트롤 UI (감정 상태, 버튼)
          if (_conversationState == ConversationState.ready) _buildReadyUI(),
          if (_conversationState == ConversationState.talking) _buildTalkingUI(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 4, right: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            const BackButton(color: Colors.white),
            const Spacer(),
            if (_conversationState == ConversationState.talking)
              TimerBuilder.periodic(
                const Duration(seconds: 1),
                builder: (context) {
                  final duration = DateTime.now().difference(_conversationStartTime!);
                  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
                  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
                  return Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyUI() {
    // 대화 준비 상태의 UI
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
            const Text(
              '오늘의 대화',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '어떤 이야기를 나누고 싶으신가요?\n편안한 마음으로 대화를 시작해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _topicController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 18),
                cursorColor: Colors.black54,
                decoration: InputDecoration(
                  hintText: '대화 주제 (선택 사항)',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.4)),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.white.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  '대화 내용은 저장되거나 녹화되지 않습니다.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startConversation, // 주제가 비어있어도 시작 가능
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(24),
                elevation: 8,
                shadowColor: Colors.white.withOpacity(0.5),
              ),
              child: const Icon(Icons.play_arrow, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTalkingUI() {
    // 대화 중 상태의 UI
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24.0).copyWith(bottom: 48),
            decoration: _bottomGradient(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _showNotesModal,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  elevation: 0,
                  heroTag: 'notes',
                  child: const Icon(Icons.edit_note_outlined, color: Colors.white),
                ),
                _buildAnalysisIndicator(),
                FloatingActionButton(
                  onPressed: _endConversation,
                  backgroundColor: Colors.red,
                  heroTag: 'end',
                  child: const Icon(Icons.stop, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
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
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlinkingRecIndicator(),
          SizedBox(width: 8),
          Text(
            '분석 중',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5),
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
    if (!_hasCameraPermission && !_isSimulator()) {
      return _buildPermissionRequiredUI();
    }
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryPermissionRequest,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // 시뮬레이터에서 카메라가 없을 때 플레이스홀더 표시
    if (_isSimulator() && _cameraController == null) {
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

  Widget _buildPermissionRequiredUI() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              '카메라 권한이 필요합니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '실시간 대화를 위해 카메라 접근 권한을 허용해주세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _retryPermissionRequest,
              child: const Text('권한 요청하기'),
            ),
            TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('설정으로 이동'),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSimulator() {
    // 시뮬레이터 환경 감지
    return !_hasCameraPermission && !_hasMicPermission;
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