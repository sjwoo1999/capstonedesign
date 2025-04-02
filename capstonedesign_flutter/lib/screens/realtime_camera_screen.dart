import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ 추가
import '../models/emotion_result.dart';
import '../providers/emotion_provider.dart';
import '../services/emotion_api_service.dart';

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  late EmotionAPIService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = EmotionAPIService();
    _initializeCamera();
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
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final base64Image = await _convertToBase64(image);
        final resultMap = await _apiService.sendImageForAnalysis(base64Image);
        final result = EmotionResult.fromApi(resultMap);

        if (mounted) {
          context.read<EmotionProvider>().setResult(result);
        }
      } catch (e) {
        debugPrint("❌ 감정 분석 실패: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<String> _convertToBase64(CameraImage image) async {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];

    final img.Image grayImage = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = yPlane.bytes[y * width + x];
        grayImage.setPixelRgb(x, y, pixel, pixel, pixel);
      }
    }

    final resized = img.copyResize(grayImage, width: 224, height: 224);
    final jpg = img.encodeJpg(resized);

    return base64Encode(jpg);
  }

  @override
  void dispose() {
    _controller?.dispose();
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: result == null
                          ? const Text('분석 중...', style: TextStyle(color: Colors.white70, fontSize: 16))
                          : Text('감정: ${result.topEmotion} (${(result.confidence * 100).toStringAsFixed(1)}%)',
                              style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}