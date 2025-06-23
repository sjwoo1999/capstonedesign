import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../services/emotion_api_services.dart';
import '../../models/emotion_result.dart';
import '../session/session_result_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _hasCameraError = false;
  String _errorMessage = '';
  late EmotionAPIService _apiService;
  DateTime _lastAnalyzed = DateTime.now();
  static const Duration frameInterval = Duration(milliseconds: 500); // ⏱️ 더 빠른 반응

  @override
  void initState() {
    super.initState();
    _apiService = EmotionAPIService(); // ✅ 꼭 초기화해줘야 함
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSessionAndCamera();
    });
  }

  Future<void> _startSessionAndCamera() async {
    final provider = context.read<EmotionProvider>();
    provider.startSession();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      
      // 카메라가 없는 경우 처리
      if (cameras.isEmpty) {
        setState(() {
          _hasCameraError = true;
          _errorMessage = '사용 가능한 카메라가 없습니다.';
        });
        return;
      }

      // 전면 카메라 찾기 (없으면 첫 번째 카메라 사용)
      CameraDescription? selectedCamera;
      try {
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
      } catch (e) {
        // 전면 카메라가 없으면 첫 번째 카메라 사용
        selectedCamera = cameras.first;
      }

      _controller = CameraController(selectedCamera, ResolutionPreset.medium);
      await _controller!.initialize();
      
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = true;
        _hasCameraError = false;
      });
      
      _startImageStream();
      
    } catch (e) {
      debugPrint('❌ 카메라 초기화 실패: $e');
      setState(() {
        _hasCameraError = true;
        _errorMessage = '카메라를 초기화할 수 없습니다.\n권한을 확인해주세요.';
      });
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (!mounted || _isAnalyzing) return;

      final now = DateTime.now();
      if (now.difference(_lastAnalyzed) < frameInterval) return;
      _lastAnalyzed = now;

      _isAnalyzing = true;
      final provider = context.read<EmotionProvider>();
      provider.startCameraAnalysis();

      try {
        final base64Image = await _convertToBase64(image);
        final resultMap = await _apiService.sendImageForAnalysis(base64Image);

        if (resultMap.containsKey('error')) {
          debugPrint('⚠️ 얼굴 인식 실패: ${resultMap['error']}');
          provider.setError('👀 얼굴이 인식되지 않았어요.');
        } else {
          debugPrint('✅ 분석 성공: ${resultMap['top_emotion']}');
          provider.clearError();
          provider.setResultFromApi(resultMap);
        }
      } catch (e) {
        debugPrint('❌ 분석 예외: $e');
        provider.setError('분석 실패: 다시 시도해 주세요.');
      } finally {
        provider.endCameraAnalysis();
        _isAnalyzing = false;
      }
    });
  }

  Future<String> _convertToBase64(CameraImage image) async {
    img.Image convertedImage;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final yPlane = image.planes[0];
      final gray = img.Image(width: image.width, height: image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = yPlane.bytes[y * image.width + x];
          gray.setPixelRgb(x, y, pixel, pixel, pixel);
        }
      }
      convertedImage = gray;
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final bytes = image.planes[0].bytes;
      final buffer = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      convertedImage = img.grayscale(buffer);
    } else {
      throw Exception("Unsupported image format: ${image.format.group}");
    }

    final cropped = img.copyCrop(
      convertedImage,
      x: (convertedImage.width * 0.15).toInt(),
      y: (convertedImage.height * 0.15).toInt(),
      width: (convertedImage.width * 0.7).toInt(),
      height: (convertedImage.height * 0.7).toInt(),
    );

    final resized = img.copyResize(cropped, width: 224, height: 224);
    final jpg = img.encodeJpg(resized);
    return base64Encode(jpg);
  }

  void _endSession() {
    final provider = context.read<EmotionProvider>();
    final result = provider.endSession();
    _controller?.dispose();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionResultScreen(result: result),
      ),
    );
  }

  void _retryCamera() {
    setState(() {
      _hasCameraError = false;
      _errorMessage = '';
      _isCameraInitialized = false;
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _hasCameraError
          ? _buildErrorView()
          : !_isCameraInitialized
              ? _buildLoadingView()
              : _buildCameraView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '카메라 오류',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('뒤로 가기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('카메라를 초기화하는 중...'),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop),
              label: const Text('분석 종료'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 50),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
