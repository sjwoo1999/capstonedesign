import 'dart:io';
import 'package:http/http.dart' as http;

class ServerDiscoveryService {
  static Future<List<String>> _generateCandidateUrls() async {
    final List<String> urls = [];
    final interfaces = await NetworkInterface.list();

    for (final interface in interfaces) {
      for (final addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          urls.add('http://${addr.address}:5001');
        }
      }
    }

    urls.add('http://127.0.0.1:5001'); // fallback local 추가
    return urls;
  }

  static Future<String?> findServer() async {
    final candidates = await _generateCandidateUrls();

    for (final url in candidates) {
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
