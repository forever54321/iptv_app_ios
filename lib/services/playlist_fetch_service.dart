import 'package:http/http.dart' as http;

class PlaylistFetchService {
  static Future<String> fetch(String url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri).timeout(
      const Duration(seconds: 30),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load playlist: HTTP ${response.statusCode}');
    }
  }

  static Future<bool> testConnection(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri).timeout(
        const Duration(seconds: 10),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
