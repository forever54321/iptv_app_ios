import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'services/pro_service.dart';
import 'services/settings_bootstrap.dart';
import 'services/reminder_service.dart';
import 'services/debug_launch_env.dart';
import 'models/playlist_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await StorageService.init();
  await ProService.instance.init();

  // Desktop-only: window manager
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 500),
      center: true,
      title: 'IPTV Player',
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Android & iOS: allow all orientations (portrait for browsing, landscape for video)
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Check if user already accepted the legal disclaimer
  final prefs = await SharedPreferences.getInstance();
  // DEBUG-only simulator hooks for layout checks (never active in release):
  //   IPTV_ROUTE=/home|/channels|/settings|/paywall|/  open that route first
  //   IPTV_PLAYLIST=http://127.0.0.1:8765/demo.m3u   add + activate a playlist
  String? debugRoute;
  if (kDebugMode && Platform.isIOS) {
    final env = debugLaunchEnv('iptv');
    debugRoute = env['IPTV_ROUTE'];
    if (debugRoute != null && debugRoute != '/') {
      await prefs.setBool('legal_disclaimer_accepted', true);
    }
    final m3u = env['IPTV_PLAYLIST'];
    if (m3u != null && (await StorageService.getAll()).isEmpty) {
      final demo = PlaylistSource(name: 'Demo TV', url: m3u);
      await StorageService.add(demo);
      await StorageService.setActive(demo);
    }
  }
  final disclaimerAccepted = prefs.getBool('legal_disclaimer_accepted') ?? false;
  final whatsNewShown = prefs.getBool('whats_new_v4_1_2_shown') ?? false;

  await ReminderService.instance.init();
  final settingsOverrides = await SettingsBootstrap.overrides();

  runApp(ProviderScope(overrides: settingsOverrides, child: IptvApp(
    disclaimerAccepted: disclaimerAccepted,
    showWhatsNew: disclaimerAccepted && !whatsNewShown,
    debugInitialLocation: debugRoute,
  )));
}
