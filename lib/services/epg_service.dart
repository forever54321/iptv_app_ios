import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/epg_program.dart';
import 'xmltv_parser.dart';

class EpgService {
  static const _cacheKey = 'epg_last_fetched';
  static const _urlKey = 'epg_url_manual';
  static const _refreshHours = 12;

  /// Fetch and parse EPG data. Uses cache if fresh enough.
  /// Fix common URL issues
  static String _fixUrl(String url) {
    url = url.trim();
    if (url.startsWith('https:/') && !url.startsWith('https://')) {
      url = 'https://' + url.substring(7).replaceAll(RegExp(r'^[:/]+'), '');
    } else if (url.startsWith('http:/') && !url.startsWith('http://')) {
      url = 'http://' + url.substring(6).replaceAll(RegExp(r'^[:/]+'), '');
    }
    return url;
  }

  static Future<Map<String, List<EpgProgram>>> fetchAndParse(String url) async {
    url = _fixUrl(url);
    final cacheFile = await _getCacheFile();
    final prefs = await SharedPreferences.getInstance();

    // Check cache freshness
    final lastFetched = prefs.getInt(_cacheKey) ?? 0;
    final hoursSince = DateTime.now().millisecondsSinceEpoch ~/ 1000 - lastFetched;
    final isFresh = hoursSince < _refreshHours * 3600;

    String xmlContent;

    if (isFresh && cacheFile.existsSync()) {
      xmlContent = await cacheFile.readAsString();
    } else {
      xmlContent = await _fetchEpg(url);
      // Cache the content
      await cacheFile.writeAsString(xmlContent);
      await prefs.setInt(_cacheKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }

    return XmltvParser.parse(xmlContent);
  }

  /// Force refresh EPG from network
  static Future<Map<String, List<EpgProgram>>> refresh(String url) async {
    url = _fixUrl(url);
    final xmlContent = await _fetchEpg(url);
    final cacheFile = await _getCacheFile();
    await cacheFile.writeAsString(xmlContent);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKey, DateTime.now().millisecondsSinceEpoch ~/ 1000);
    return XmltvParser.parse(xmlContent);
  }

  static Future<String> _fetchEpg(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'VLC/3.0.20 LibVLC/3.0.20'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch EPG: HTTP ${response.statusCode}');
    }

    // Handle gzip
    return XmltvParser.decompressIfNeeded(response.bodyBytes);
  }

  static Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/epg_cache.xml');
  }

  /// Get the manually set EPG URL
  static Future<String?> getManualUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_urlKey);
  }

  /// Set manual EPG URL
  static Future<void> setManualUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_urlKey);
    } else {
      await prefs.setString(_urlKey, url);
    }
  }

  /// Clear EPG cache
  static Future<void> clearCache() async {
    final cacheFile = await _getCacheFile();
    if (cacheFile.existsSync()) {
      await cacheFile.delete();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
