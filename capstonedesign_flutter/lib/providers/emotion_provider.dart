// lib/providers/emotion_provider.dart
import 'package:flutter/material.dart';
import '../models/emotion_results.dart';
import '../services/api_service.dart';

class EmotionProvider with ChangeNotifier {
  EmotionResult? _result;
  bool _isLoading = false;

  EmotionResult? get result => _result;
  bool get isLoading => _isLoading;

  final ApiService _apiService = ApiService();

  Future<void> analyze({String? image, String? text}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _result = await _apiService.analyzeEmotion(image: image, text: text);
    } catch (e) {
      print('Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
