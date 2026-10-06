import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One reminder the user set from the program guide.
class ProgramReminder {
  final String channelUrl;
  final String channelTitle;
  final String programTitle;
  final DateTime start;

  const ProgramReminder({
    required this.channelUrl,
    required this.channelTitle,
    required this.programTitle,
    required this.start,
  });

  /// Stable key: one reminder per channel + start time.
  String get key => '$channelUrl|${start.toUtc().millisecondsSinceEpoch}';

  /// Notification id derived from the key (fits in a signed 31-bit int).
  int get notificationId => key.hashCode & 0x7fffffff;

  Map<String, dynamic> toJson() => {
        'channelUrl': channelUrl,
        'channelTitle': channelTitle,
        'programTitle': programTitle,
        'start': start.toUtc().toIso8601String(),
      };

  static ProgramReminder? fromJson(Object? j) {
    if (j is! Map) return null;
    final start = DateTime.tryParse('${j['start']}');
    final url = j['channelUrl'];
    if (start == null || url is! String) return null;
    return ProgramReminder(
      channelUrl: url,
      channelTitle: '${j['channelTitle'] ?? ''}',
      programTitle: '${j['programTitle'] ?? ''}',
      start: start,
    );
  }
}

/// Pure timing rules — kept free of plugins so tests can check them.
class ReminderTiming {
  /// Lead-time choices in minutes; null = "Not selected" (reminders off).
  static const options = <int?>[null, 0, 5, 10, 15, 30];

  static String label(int? minutes) {
    if (minutes == null) return 'Not selected';
    if (minutes == 0) return 'When it starts';
    return '$minutes min before';
  }

  /// When the notification should fire, or null if that moment has passed
  /// (a reminder for a show that already started is pointless).
  static DateTime? fireTime(DateTime start, int leadMinutes, DateTime now) {
    final at = start.subtract(Duration(minutes: leadMinutes));
    return at.isAfter(now) ? at : null;
  }
}

/// Schedules "your program is about to start" local notifications.
///
/// Reminders are saved in SharedPreferences so they survive app restarts and
/// can be rescheduled when the lead time changes. Tapping a notification hands
/// its channel URL to [onOpenChannel].
class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  static const _listKey = 'program_reminders';
  static const _leadKey = 'program_reminder_lead';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// Set by the app: open the player on this channel.
  void Function(String channelUrl)? onOpenChannel;
  String? _pendingLaunchUrl;

  /// Windows/Linux need separate notification setup the app doesn't have yet.
  static bool get supported => Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

  Future<void> init() async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        iOS: darwin,
        macOS: darwin,
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => _open(r.payload),
    );
    _ready = true;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _pendingLaunchUrl = launch?.notificationResponse?.payload;
    }
    await _prunePast();
  }

  /// Called once the UI is up: replays a tap that launched the app.
  void consumeLaunchTap() {
    final url = _pendingLaunchUrl;
    _pendingLaunchUrl = null;
    if (url != null) _open(url);
  }

  void _open(String? url) {
    if (url != null && url.isNotEmpty) onOpenChannel?.call(url);
  }

  Future<int?> leadMinutes() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_leadKey) ? p.getInt(_leadKey) : null;
  }

  Future<void> setLeadMinutes(int? minutes) async {
    final p = await SharedPreferences.getInstance();
    if (minutes == null) {
      await p.remove(_leadKey);
      await _cancelAllScheduled();
      await p.remove(_listKey);
    } else {
      await p.setInt(_leadKey, minutes);
      await _rescheduleAll();
    }
  }

  Future<List<ProgramReminder>> reminders() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_listKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map(ProgramReminder.fromJson).whereType<ProgramReminder>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isSet(ProgramReminder r) async =>
      (await reminders()).any((x) => x.key == r.key);

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true, badge: false) ??
          false;
    }
    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true, badge: false) ??
          false;
    }
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    return false;
  }

  /// Adds the reminder and schedules it. Returns false when the program
  /// starts too soon for the chosen lead time, or notifications are blocked.
  Future<bool> add(ProgramReminder r, int lead) async {
    if (!supported) return false;
    await init();
    if (ReminderTiming.fireTime(r.start, lead, DateTime.now()) == null) return false;
    if (!await requestPermission()) return false;
    final list = (await reminders())..removeWhere((x) => x.key == r.key);
    list.add(r);
    await _save(list);
    await _schedule(r, lead);
    return true;
  }

  Future<void> remove(ProgramReminder r) async {
    await init();
    await _plugin.cancel(id: r.notificationId);
    final list = (await reminders())..removeWhere((x) => x.key == r.key);
    await _save(list);
  }

  Future<void> _schedule(ProgramReminder r, int lead) async {
    final at = ReminderTiming.fireTime(r.start, lead, DateTime.now());
    if (at == null) return;
    final when = lead == 0 ? 'is starting now' : 'starts in $lead min';
    await _plugin.zonedSchedule(
      id: r.notificationId,
      title: r.programTitle,
      body: '$when on ${r.channelTitle} — tap to watch',
      // An absolute instant: UTC avoids needing the device's zone name.
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        macOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        android: AndroidNotificationDetails(
          'program_reminders',
          'Program reminders',
          channelDescription: 'Alerts before a program you chose starts',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: r.channelUrl,
    );
  }

  Future<void> _rescheduleAll() async {
    await init();
    final lead = await leadMinutes();
    await _cancelAllScheduled();
    if (lead == null) return;
    for (final r in await reminders()) {
      await _schedule(r, lead);
    }
  }

  Future<void> _cancelAllScheduled() async {
    if (!_ready) return;
    for (final r in await reminders()) {
      await _plugin.cancel(id: r.notificationId);
    }
  }

  Future<void> _prunePast() async {
    final now = DateTime.now();
    final list = await reminders();
    final kept = list.where((r) => r.start.isAfter(now)).toList();
    if (kept.length != list.length) await _save(kept);
  }

  Future<void> _save(List<ProgramReminder> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_listKey, jsonEncode(list.map((r) => r.toJson()).toList()));
  }
}
