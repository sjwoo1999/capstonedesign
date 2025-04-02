import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../services/tflite_service.dart';
import '../models/emotion_result.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  late TFLiteService _tfliteService;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    try {
      _tfliteService = Provider.of<TFLiteService>(context, listen: false);
      await _tfliteService.loadModel();

      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller!.initialize();

      if (!mounted) return;
      setState(() => _isCameraInitialized = true);

      _startLiveAnalysis();
    } catch (e) {
      debugPrint('❌ 시스템 초기화 중 오류 발생: $e');
    }
  }

  void _startLiveAnalysis() {
    if (!_tfliteService.isModelLoaded) {
      debugPrint('❌ 모델이 로드되지 않아 분석 불가');
      return;
    }

    _controller?.startImageStream((CameraImage image) {
      if (!mounted ||
          !_controller!.value.isStreamingImages ||
          _isDetecting ||
          !_tfliteService.isInterpreterReady) {
        return;
      }

      _isDetecting = true;
      final imageCopy = image;

      Future.microtask(() async {
        try {
          final input = _tfliteService.preprocessCameraImage(imageCopy);
          final preds = await _tfliteService.infer(input);
          final result = EmotionResult.fromLocal(preds);

          if (mounted) {
            context.read<EmotionProvider>().setResult(result);
          }
        } catch (e, stackTrace) {
          debugPrint('❌ 실시간 분석 중 오류: $e');
          debugPrint(stackTrace.toString());
        } finally {
          _isDetecting = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tfliteService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = context.watch<EmotionProvider>().result;

    return Scaffold(
      appBar: AppBar(title: const Text('실시간 감정 분석')),
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_controller!),
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: result == null
                          ? const Text(
                              '분석 중...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            )
                          : Text(
                              '감정: ${result.topEmotion}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 18),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
