import 'dart:io';

import 'package:flutter/foundation.dart';

/// DEBUG-only launch hooks for simulator layout checks. Read from the process
/// environment (`simctl launch` with SIMCTL_CHILD_*), falling back to a
/// KEY=VALUE file at `/private/tmp/duo-hooks/NAME.env` on the Mac (simulator
/// apps can read host paths). Always empty in profile/release builds.
Map<String, String> debugLaunchEnv(String name) {
  if (!kDebugMode) return const {};
  final out = <String, String>{...Platform.environment};
  try {
    final f = File('/private/tmp/duo-hooks/$name.env');
    if (f.existsSync()) {
      for (final line in f.readAsLinesSync()) {
        final i = line.indexOf('=');
        if (i > 0) {
          out[line.substring(0, i).trim()] = line.substring(i + 1).trim();
        }
      }
    }
  } on FileSystemException catch (_) {}
  return out;
}
