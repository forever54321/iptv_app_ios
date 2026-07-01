import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import '../models/epg_program.dart';

class XmltvParser {
  /// Parse XMLTV content into a map of channelId -> list of programs.
  /// Runs in an isolate to avoid blocking the UI thread.
  static Future<Map<String, List<EpgProgram>>> parse(String xmlContent) async {
    return compute(_parseXmltv, xmlContent);
  }

  /// Parse XMLTV date format: "20260402060000 +0000"
  static DateTime? parseXmltvDate(String dateStr) {
    try {
      dateStr = dateStr.trim();
      // Format: YYYYMMDDHHmmss +ZZZZ or YYYYMMDDHHmmss
      final parts = dateStr.split(' ');
      final datePart = parts[0];

      if (datePart.length < 14) return null;

      final year = int.parse(datePart.substring(0, 4));
      final month = int.parse(datePart.substring(4, 6));
      final day = int.parse(datePart.substring(6, 8));
      final hour = int.parse(datePart.substring(8, 10));
      final minute = int.parse(datePart.substring(10, 12));
      final second = int.parse(datePart.substring(12, 14));

      if (parts.length > 1) {
        // Has timezone offset like +0000 or -0500
        final tzStr = parts[1];
        final tzSign = tzStr.startsWith('-') ? -1 : 1;
        final tzHours = int.parse(tzStr.substring(1, 3));
        final tzMinutes = int.parse(tzStr.substring(3, 5));
        final offset = Duration(hours: tzHours, minutes: tzMinutes) * tzSign;

        return DateTime.utc(year, month, day, hour, minute, second)
            .subtract(offset)
            .toLocal();
      }

      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }

  /// Decompress gzip content if needed
  static String decompressIfNeeded(List<int> bytes) {
    // Check for gzip magic bytes
    if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
      final decompressed = gzip.decode(bytes);
      return String.fromCharCodes(decompressed);
    }
    return String.fromCharCodes(bytes);
  }
}

/// Top-level function for isolate parsing
Map<String, List<EpgProgram>> _parseXmltv(String xmlContent) {
  final programs = <String, List<EpgProgram>>{};

  try {
    final document = XmlDocument.parse(xmlContent);
    final tv = document.rootElement;

    // Only keep programs within a 48-hour window
    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 1));
    final windowEnd = now.add(const Duration(hours: 48));

    for (final programme in tv.findAllElements('programme')) {
      final channelId = programme.getAttribute('channel');
      final startStr = programme.getAttribute('start');
      final stopStr = programme.getAttribute('stop');

      if (channelId == null || startStr == null || stopStr == null) continue;

      final start = XmltvParser.parseXmltvDate(startStr);
      final stop = XmltvParser.parseXmltvDate(stopStr);

      if (start == null || stop == null) continue;

      // Filter to window
      if (stop.isBefore(windowStart) || start.isAfter(windowEnd)) continue;

      final titleEl = programme.findElements('title').firstOrNull;
      final descEl = programme.findElements('desc').firstOrNull;
      final catEl = programme.findElements('category').firstOrNull;

      if (titleEl == null) continue;

      final program = EpgProgram(
        channelId: channelId,
        start: start,
        stop: stop,
        title: titleEl.innerText,
        description: descEl?.innerText,
        category: catEl?.innerText,
      );

      (programs[channelId] ??= []).add(program);
    }

    // Sort each channel's programs by start time
    for (final list in programs.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
  } catch (_) {
    // Return empty on parse error
  }

  return programs;
}
