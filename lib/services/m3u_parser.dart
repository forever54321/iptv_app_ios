import '../models/m3u_entry.dart';

class M3uParser {
  static final _attrRegex = RegExp(r'(\w[\w-]*)="([^"]*)"');
  static final _durationRegex = RegExp(r'#EXTINF:\s*(-?\d+)');

  /// Extract EPG URL from the M3U content
  /// Checks #EXTM3U header for url-tvg="..." and also x-tvg-url="..."
  static String? extractEpgUrl(String content) {
    // Check first few lines for the EPG URL
    final lines = content.split('\n');
    final searchLines = lines.length > 10 ? lines.sublist(0, 10) : lines;

    for (final line in searchLines) {
      final trimmed = line.trim();
      // Check for url-tvg="..."
      final match1 = RegExp(r'url-tvg="([^"]*)"').firstMatch(trimmed);
      if (match1 != null && match1.group(1)!.isNotEmpty) return _fixUrl(match1.group(1)!);

      // Check for x-tvg-url="..."
      final match2 = RegExp(r'x-tvg-url="([^"]*)"').firstMatch(trimmed);
      if (match2 != null && match2.group(1)!.isNotEmpty) return _fixUrl(match2.group(1)!);
    }
    return null;
  }

  /// Fix common URL issues (missing slashes, encoding)
  static String _fixUrl(String url) {
    url = url.trim();
    // Fix "https:/" or "http:/" or "https:/:/" missing slashes
    if (url.startsWith('https:/') && !url.startsWith('https://')) {
      url = 'https://' + url.substring(7).replaceAll(RegExp(r'^[:/]+'), '');
    } else if (url.startsWith('http:/') && !url.startsWith('http://')) {
      url = 'http://' + url.substring(6).replaceAll(RegExp(r'^[:/]+'), '');
    }
    return url;
  }

  /// Build EPG URL for Xtream Codes server
  static String? buildXtreamEpgUrl(String serverUrl, String username, String password) {
    try {
      var base = serverUrl;
      // Strip path to get base URL
      if (base.contains('/get.php')) {
        base = base.substring(0, base.indexOf('/get.php'));
      }
      if (base.endsWith('/')) base = base.substring(0, base.length - 1);
      final u = Uri.encodeQueryComponent(username);
      final p = Uri.encodeQueryComponent(password);
      return '$base/xmltv.php?username=$u&password=$p';
    } catch (_) {
      return null;
    }
  }

  static List<M3uEntry> parse(String content) {
    final lines = content.split('\n').map((l) => l.trim()).toList();
    final entries = <M3uEntry>[];

    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (!line.startsWith('#EXTINF:')) {
        i++;
        continue;
      }

      // Parse EXTINF line
      final attrs = <String, String>{};
      for (final match in _attrRegex.allMatches(line)) {
        attrs[match.group(1)!.toLowerCase()] = match.group(2)!;
      }

      // Duration
      final durMatch = _durationRegex.firstMatch(line);
      final duration = durMatch != null ? int.tryParse(durMatch.group(1)!) ?? -1 : -1;

      // Display name: text after the last comma
      final commaIndex = line.lastIndexOf(',');
      final title = commaIndex != -1 && commaIndex < line.length - 1
          ? line.substring(commaIndex + 1).trim()
          : attrs['tvg-name'] ?? 'Unknown';

      // Find URL on next non-empty, non-comment line
      i++;
      String? url;
      while (i < lines.length) {
        final nextLine = lines[i];
        if (nextLine.isEmpty || nextLine.startsWith('#')) {
          i++;
          continue;
        }
        url = nextLine;
        i++;
        break;
      }

      if (url != null && url.isNotEmpty) {
        entries.add(M3uEntry(
          title: title,
          url: url,
          groupTitle: attrs['group-title'],
          tvgName: attrs['tvg-name'],
          tvgLogo: attrs['tvg-logo'],
          tvgId: attrs['tvg-id'],
          tvgLanguage: attrs['tvg-language'],
          duration: duration,
        ));
      }
    }

    return entries;
  }
}
