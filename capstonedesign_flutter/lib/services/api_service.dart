import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emotion_results.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<EmotionResult> analyzeEmotion({String? image, String? text}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (image != null) 'image': image,
        if (text != null) 'text': text,
      }),
    );

    if (response.statusCode == 200) {
      return EmotionResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to analyze emotion: ${response.statusCode}');
    }
  }
}
