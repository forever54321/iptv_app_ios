import 'dart:io';
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
  final disclaimerAccepted = prefs.getBool('legal_disclaimer_accepted') ?? false;
  final whatsNewShown = prefs.getBool('whats_new_v4_1_2_shown') ?? false;

  runApp(ProviderScope(child: IptvApp(
    disclaimerAccepted: disclaimerAccepted,
    showWhatsNew: disclaimerAccepted && !whatsNewShown,
  )));
}
