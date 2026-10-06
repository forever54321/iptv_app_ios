import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/parental_control_screen.dart';
import 'parental_pin_service.dart';

/// Reads every saved setting BEFORE the first screen is built.
///
/// These providers used to be filled in only when the Settings / Parental
/// Control screens were opened, so after each launch the app ran on
/// defaults: groups the user had locked were NOT locked, and switches the
/// user turned off were back on, until they happened to visit Settings.
class SettingsBootstrap {
  static Future<List<Override>> overrides() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = await ParentalPinService.hasPin();
    final locked = hasPin
        ? (prefs.getStringList('parental_locked_groups') ?? const <String>[]).toSet()
        : <String>{};
    return [
      recentChannelsProvider.overrideWith((ref) => prefs.getBool('recent_channels') ?? true),
      organizeByGroupsProvider.overrideWith((ref) => prefs.getBool('organize_by_groups') ?? true),
      defaultAspectRatioProvider.overrideWith((ref) => prefs.getString('aspect_ratio') ?? '16:9'),
      parentalControlProvider.overrideWith((ref) => hasPin),
      parentalLockedGroupsProvider.overrideWith((ref) => locked),
    ];
  }
}
