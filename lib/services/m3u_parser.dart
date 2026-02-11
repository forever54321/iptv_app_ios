import '../models/m3u_entry.dart';

class M3uParser {
  static final _attrRegex = RegExp(r'(\w[\w-]*)="([^"]*)"');
  static final _durationRegex = RegExp(r'#EXTINF:\s*(-?\d+)');

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
