import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/emotion_result.dart';
import '../providers/emotion_provider.dart';
import '../services/emotion_api_services.dart';
import '../widgets/emotion_chart.dart';
import '../constants/emotion_constants.dart'; // ✅ 추가

class RealtimeCameraScreen extends StatefulWidget {
  const RealtimeCameraScreen({super.key});

  @override
  State<RealtimeCameraScreen> createState() => _RealtimeCameraScreenState();
}

class _RealtimeCameraScreenState extends State<RealtimeCameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  late EmotionAPIService _apiService;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  DateTime _lastAnalyzed = DateTime.now();
  static const Duration frameInterval = Duration(milliseconds: 1000);

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
          provider.setError('👀 얼굴이 인식되지 않았어요.\n화면을 바라봐 주세요.');
        } else {
          provider.clearError();
          provider.setResultFromApi(resultMap);
          _retryCount = 0;
        }
      } catch (e) {
        _retryCount++;
        if (_retryCount >= _maxRetries) {
          provider.setError('서버 연결에 실패했어요.\n잠시 후 다시 시도해 주세요.');
          _controller?.stopImageStream();
        }
        debugPrint('❌ 분석 실패: $e');
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmotionProvider>();
    final result = provider.result;
    final errorMessage = provider.errorMessage;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("실시간 감정 분석", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 6,
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: EmotionChart(
                            probabilities: result?.probabilities ?? {},
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildResultMessage(result, errorMessage),
                        const SizedBox(height: 12),
                        Text(
                          '🙌 영상은 저장되지 않아요.\n표정 데이터만 분석돼요.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildResultMessage(EmotionResult? result, String? error) {
    if (error != null && error.isNotEmpty) {
      return Text(
        error,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.redAccent,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (result != null) {
      final nickname = emotionNicknameMap[result.topEmotion] ?? result.topEmotion;
      final color = emotionColorMap[result.topEmotion] ?? Colors.black87;

      return Text(
        '$nickname\n(${(result.confidence * 100).toStringAsFixed(1)}%)',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Text(
        '분석 중...',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.grey,
          fontSize: 15,
        ),
      );
    }
  }
}