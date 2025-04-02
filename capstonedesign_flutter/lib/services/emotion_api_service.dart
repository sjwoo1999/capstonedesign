import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmotionAPIService {
  final String baseUrl;

  EmotionAPIService({String? customUrl})
      : baseUrl = customUrl ?? (dotenv.env['EMOTION_API_URL'] ?? 'http://localhost:5001');

  Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"image": base64Image}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API 호출 실패: ${response.body}');
    }
  }
}