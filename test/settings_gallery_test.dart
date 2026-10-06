@Tags(['gallery'])
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv_app/core/theme.dart';
import 'package:iptv_app/screens/settings/settings_screen.dart';

Future<void> _fonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/Users/saedzakari/development/flutter';
  for (final e in {'Roboto': ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf'], 'MaterialIcons': ['MaterialIcons-Regular.otf']}.entries) {
    final l = FontLoader(e.key);
    for (final f in e.value) {
      final file = File('$root/bin/cache/artifacts/material_fonts/$f');
      if (file.existsSync()) l.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
    }
    await l.load();
  }
}

void main() {
  testWidgets('settings screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const MethodChannel('dev.fluttercommunity.plus/package_info')
        .setMockMethodCallHandler(null);
    await _fonts();
    tester.view.physicalSize = const Size(1170, 3400);
    tester.view.devicePixelRatio = 3;
    await tester.pumpWidget(ProviderScope(
      overrides: [parentalControlProvider.overrideWith((ref) => false)],
      child: MaterialApp(
        theme: AppTheme.dark.copyWith(
          textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
          appBarTheme: AppTheme.dark.appBarTheme.copyWith(
            titleTextStyle: AppTheme.dark.appBarTheme.titleTextStyle!.copyWith(fontFamily: 'Roboto'),
          ),
        ),
        home: const SettingsScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(SettingsScreen), matchesGoldenFile('goldens/settings.png'));
  });
}
