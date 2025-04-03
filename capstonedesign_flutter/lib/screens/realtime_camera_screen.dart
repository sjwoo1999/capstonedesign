import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  int _analysisAttempts = 0;

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
      if (_isDetecting || !_controller!.value.isStreamingImages) return;
      _isDetecting = true;

      try {
        _analysisAttempts += 1;
        final base64Image = await _convertToBase64(image);
        final resultMap = await _apiService.sendImageForAnalysis(base64Image);

        if (resultMap.containsKey('error')) {
          // ❌ 얼굴 인식 실패
          if (mounted) {
            context
                .read<EmotionProvider>()
                .setError('얼굴이 인식되지 않았어요. 화면을 바라봐 주세요.');
          }
          debugPrint(
              '❌ 분석 실패[시도 $_analysisAttempts회] → No face detected @ ${DateTime.now()}');
        } else {
          // ✅ 감정 분석 성공
          final result = EmotionResult.fromApi(resultMap);
          if (mounted) {
            context.read<EmotionProvider>()
              ..clearError()
              ..setResult(result);
          }
          debugPrint(
              '✅ 분석 성공[시도 $_analysisAttempts회] → ${result.topEmotion} (${(result.confidence * 100).toStringAsFixed(1)}%)');
        }
      } catch (e) {
        debugPrint("❌ 분석 예외[시도 $_analysisAttempts회]: $e");
      } finally {
        await Future.delayed(const Duration(milliseconds: 500));
        _isDetecting = false;
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = context.watch<EmotionProvider>().result;
    final errorMessage = context.watch<EmotionProvider>().errorMessage;

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
                      child: _buildMessage(result, errorMessage),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessage(EmotionResult? result, String? error) {
    if (error != null && error.isNotEmpty) {
      return Text(error,
          style: const TextStyle(color: Colors.redAccent, fontSize: 16));
    } else if (result != null) {
      return Text(
        '감정: ${result.topEmotion} (${(result.confidence * 100).toStringAsFixed(1)}%)',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      );
    } else {
      return const Text('분석 중...',
          style: TextStyle(color: Colors.white70, fontSize: 16));
    }
  }
}
