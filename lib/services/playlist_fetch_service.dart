import 'package:http/http.dart' as http;

class PlaylistFetchService {
  /// Session cache: playlist body by URL. The channel list downloads ONCE per
  /// app session; navigating to the player and back (or anything else that
  /// rebuilds the channel provider) is served from memory. Cleared only by an
  /// explicit refresh or app relaunch.
  static final Map<String, String> _sessionCache = {};

  static void clearCache() => _sessionCache.clear();

  static Future<String> fetch(String url, {bool force = false}) async {
    if (!force) {
      final cached = _sessionCache[url];
      if (cached != null) return cached;
    }
    final uri = Uri.parse(url);
    final response = await http.get(uri).timeout(
      const Duration(seconds: 30),
    );

    if (response.statusCode == 200) {
      _sessionCache[url] = response.body;
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
