// lib/services/tflite_service.dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TFLiteService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('mobilenetv2.tflite');
  }

  Future<List<double>> predict(Uint8List imageBytes) async {
    // 이미지 전처리 (48x48, RGB)
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

    img.Image resized = img.copyResize(image, width: 48, height: 48);
    var input = Float32List(1 * 48 * 48 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < 48; y++) {
      for (int x = 0; x < 48; x++) {
        var pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    // 모델 예측
    var output = List.filled(1 * 7, 0.0).reshape([1, 7]);
    _interpreter.run(input.reshape([1, 48, 48, 3]), output);

    return output[0].cast<double>();
  }
}
