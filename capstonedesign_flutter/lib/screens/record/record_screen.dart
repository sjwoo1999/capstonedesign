// lib/screens/record/record_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../../providers/emotion_provider.dart';
import '../../services/emotion_api_services.dart';
import '../../constants/emotion_constants.dart';
import '../../models/emotion_result.dart';
import '../session/session_result_screen.dart'; // ✅ 수정 포인트!

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  late EmotionAPIService _apiService;
  DateTime _lastAnalyzed = DateTime.now();
  static const Duration frameInterval = Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    _apiService = EmotionAPIService();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
    _startImageStream();
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (!mounted) return;
      if (_isAnalyzing) return;

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
          provider.setError('👀 얼굴이 인식되지 않았어요.');
        } else {
          provider.clearError();
          provider.setResultFromApi(resultMap);
        }
      } catch (e) {
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

  void _startSession() async {
    final provider = context.read<EmotionProvider>();
    provider.startSession();
    await _initializeCamera();
  }

  void _endSession() {
    final provider = context.read<EmotionProvider>();
    final result = provider.endSession();
    _controller?.dispose();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SessionResultScreen(result: result), // ✅ 수정 포인트
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSessionActive = context.watch<EmotionProvider>().isSessionActive;

    return Scaffold(
      appBar: AppBar(title: const Text('감정 분석')),
      body: !_isCameraInitialized
          ? Center(
              child: ElevatedButton(
                onPressed: _startSession,
                child: const Text('분석 시작'),
              ),
            )
          : Column(
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
                )
              ],
            ),
    );
  }
}
