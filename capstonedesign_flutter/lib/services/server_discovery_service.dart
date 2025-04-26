import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerDiscoveryService {
  static const List<String> candidateUrls = [
    'http://10.121.130.246:5001',
    'http://172.30.1.73:5001',
    'http://127.0.0.1:5001',
    // 필요한 만큼 추가 가능
  ];

  static Future<String?> findServer() async {
    for (final url in candidateUrls) {
      try {
        final response = await http.get(Uri.parse('$url/whoami')).timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          print('✅ 서버 발견: $url');
          return url;
        }
      } catch (_) {
        print('❌ 서버 접속 실패: $url');
      }
    }
    return null;
  }
}