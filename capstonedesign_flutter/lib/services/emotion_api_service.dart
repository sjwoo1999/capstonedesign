import 'dart:convert';
import 'package:http/http.dart' as http;

class EmotionAPIService {
  final String baseUrl;

  EmotionAPIService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> sendImageForAnalysis(
      String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"image": base64Image}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('API 호출 실패: ${response.body}');
    }
  }
}
