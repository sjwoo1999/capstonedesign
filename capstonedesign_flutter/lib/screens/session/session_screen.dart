import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../../models/vad_emotion.dart';
import '../analysis/analysis_result_screen.dart';
import 'package:timer_builder/timer_builder.dart';


// 대화 상태를 명확하게 정의
enum ConversationState {
  preparing,     // 준비 중 (카메라 초기화)
  ready,         // 대화 시작 준비 완료
  talking,       // 대화 중 (실시간 분석)
  ending,        // 대화 종료 중
  analyzing      // 백그라운드 분석 중
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
  String _cameraError = '';

  // 대화 관련
  DateTime? _conversationStartTime;
  DateTime? _conversationEndTime;
  List<String> _conversationNotes = [];
  String _currentEmotion = '중립';

  @override
  void initState() {
    super.initState();
    print('🚀 실시간 대화 화면 초기화 시작');
    _checkCameraPermission();
    
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
    super.dispose();
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
        _initializeCamera();
      } else if (status.isDenied) {
        print('❌ 카메라 권한 거부됨, 요청 시작');
        _requestCameraPermission();
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

  Future<void> _requestCameraPermission() async {
    try {
      print('🔐 카메라 권한 요청 시작');
      final result = await Permission.camera.request();
      print('📱 권한 요청 결과: $result');
      
      setState(() {
        _hasCameraPermission = result.isGranted;
      });
      
      if (result.isGranted) {
        print('✅ 권한 허용됨, 카메라 초기화 시작');
        _initializeCamera();
      } else if (result.isPermanentlyDenied) {
        print('🚫 영구 거부됨, 설정으로 이동');
        _showPermissionDialog();
      } else {
        print('❌ 권한 거부됨 (일시적)');
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      print('❌ 권한 요청 중 오류: $e');
      setState(() {
        _hasCameraPermission = false;
        _cameraError = '권한 요청 실패: $e';
      });
    }
  }

  void _retryPermissionRequest() {
    print('🔄 권한 요청 재시도');
    setState(() {
      _hasCameraPermission = false;
      _cameraError = '';
    });
    _requestCameraPermission();
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
              _requestCameraPermission();
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

  void _endConversation() {
    setState(() {
      _conversationState = ConversationState.ending;
      _conversationEndTime = DateTime.now();
    });
    
    print('🔚 대화 종료');
    
    // 2초 후 백그라운드 분석 시작
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _conversationState = ConversationState.analyzing;
        });
        _startBackgroundAnalysis();
      }
    });
  }

  void _startRealTimeAnalysis() {
    // 실시간 감정 변화 시뮬레이션
    const emotions = ['기쁨', '평온', '슬픔', '불안', '분노', '중립'];
    int emotionIndex = 0;
    
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_conversationState != ConversationState.talking) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentEmotion = emotions[emotionIndex];
        emotionIndex = (emotionIndex + 1) % emotions.length;
      });
      
      print('😊 현재 감정: $_currentEmotion');
    });
  }

  void _startBackgroundAnalysis() {
    print('📊 백그라운드 분석 시작');
    
    // 분석 완료 시뮬레이션 (5초 후)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _showAnalysisCompleteDialog();
      }
    });
  }

  void _showAnalysisCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('분석 완료!'),
        content: const Text(
          '대화 분석이 완료되었습니다.\n'
          '상세한 감정 분석 리포트를 확인해보세요.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 홈으로 돌아가기
            },
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showAnalysisResult();
            },
            child: const Text('리포트 보기'),
          ),
        ],
      ),
    );
  }

  void _showAnalysisResult() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const AnalysisResultScreen(),
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

  @override
  Widget build(BuildContext context) {
    final theme = BeMoreTheme.lightTheme;
    return Scaffold(
      body: Stack(
        children: [
          // 카메라 미리보기 (전체 화면 배경)
          Positioned.fill(child: _buildCameraPreview()),

          // 상단 UI (뒤로가기, 제목, 대화 시간)
          _buildTopBar(theme),

          // 하단 컨트롤 시트
          _buildConversationSheet(),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
            const Text(
              '실시간 대화',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_conversationState == ConversationState.talking)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: TimerBuilder.periodic(
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
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
              )
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // 시트 핸들
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
              // 여기에 상태별 UI 추가
              if (_conversationState == ConversationState.ready)
                _buildStartCardContent(),
              if (_conversationState == ConversationState.talking)
                _buildTalkingCardContent(),
              if (_conversationState == ConversationState.analyzing || _conversationState == ConversationState.ending)
                _buildAnalyzingCardContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    if (!_hasCameraPermission) {
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
  
  Widget _buildStartCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('대화 시작', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('어떤 주제에 대해 이야기를 나누고 싶으신가요?'),
          const SizedBox(height: 12),
          TextField(
            controller: _topicController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '예: 오늘 있었던 일, 스트레스 받는 상황, 기쁜 일 등',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _conversationTopic.isNotEmpty ? _startConversation : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _conversationTopic.isNotEmpty 
                ? Theme.of(context).colorScheme.primary 
                : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('대화 시작', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTalkingCardContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('실시간 감정 분석', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BeMoreTheme.emotionColors[_currentEmotion]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BeMoreTheme.emotionColors[_currentEmotion]?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sentiment_satisfied, // TODO: 감정별 아이콘 변경
                  color: BeMoreTheme.emotionColors[_currentEmotion] ?? Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('현재 감정', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(
                      _currentEmotion,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BeMoreTheme.emotionColors[_currentEmotion] ?? Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('메모 추가 (선택사항)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: '특별히 기록하고 싶은 내용이 있다면...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _addNote,
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_conversationNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('메모 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._conversationNotes.map((note) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(note),
            )),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _endConversation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('대화 종료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyzingCardContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            strokeWidth: 4,
          ),
          const SizedBox(height: 24),
          const Text('대화 분석 중...', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            '수집된 데이터를 종합하여 상세한 감정 분석 리포트를 작성하고 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
} 