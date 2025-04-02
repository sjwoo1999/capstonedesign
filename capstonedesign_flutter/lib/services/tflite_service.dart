import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;
  bool _isInterpreterReady = false;
  bool _isRunning = false;

  /// 모델 로드 및 텐서 할당
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/model.tflite");
      _interpreter!.allocateTensors(); // 초기화 시점에서 명시적으로 할당
      _isInterpreterReady = true;
      print('✅ TFLite 모델 로딩 및 텐서 할당 완료!');
    } catch (e) {
      _isInterpreterReady = false;
      print('❌ 모델 로딩 실패: $e');
    }
  }

  bool get isModelLoaded => _interpreter != null;
  bool get isInterpreterReady => _isInterpreterReady;
  bool get isRunning => _isRunning;
  bool get isReady => _interpreter != null && _isInterpreterReady;

  /// 실시간 카메라 프레임 전처리: 48x48 grayscale 변환
  Float32List preprocessCameraImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0].bytes;

    final grayImage = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixelValue = yPlane[y * width + x];
        final grayColor = img.ColorRgb8(pixelValue, pixelValue, pixelValue);
        grayImage.setPixel(x, y, grayColor);
      }
    }

    final resizedImage = img.copyResize(grayImage, width: 48, height: 48);
    final floatBuffer = Float32List(48 * 48);
    for (int i = 0; i < 48 * 48; i++) {
      final pixel = resizedImage.getPixel(i % 48, i ~/ 48);
      floatBuffer[i] =
          (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
    }

    return floatBuffer;
  }

  /// 감정 추론 수행
  Future<List<double>> infer(Float32List input) async {
    if (!isReady) {
      throw Exception("❌ Interpreter not ready (모델 미로딩 혹은 텐서 미할당)");
    }

    if (_isRunning) {
      throw Exception("⚠️ 현재 다른 추론이 진행 중입니다.");
    }

    _isRunning = true;
    try {
      final inputTensor = input.reshape([1, 48, 48, 1]);
      final outputTensor = List<double>.filled(7, 0.0).reshape([1, 7]);

      _interpreter!.run(inputTensor, outputTensor);

      return List<double>.from(outputTensor[0]);
    } catch (e) {
      print("❌ 추론 중 오류 발생: $e");
      rethrow;
    } finally {
      _isRunning = false;
    }
  }

  /// 리소스 해제
  void dispose() {
    if (_interpreter != null) {
      _interpreter!.close();
      print('🧹 인터프리터 메모리 해제 완료');
    }
    _interpreter = null;
    _isInterpreterReady = false;
    _isRunning = false;
  }
}
