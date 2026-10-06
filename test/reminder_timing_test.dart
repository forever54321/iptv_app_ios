import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/services/reminder_service.dart';

void main() {
  final start = DateTime(2026, 10, 5, 20, 0);

  test('fires lead minutes before the start', () {
    expect(ReminderTiming.fireTime(start, 10, DateTime(2026, 10, 5, 19, 0)), DateTime(2026, 10, 5, 19, 50));
  });
  test('"When it starts" fires at the start', () {
    expect(ReminderTiming.fireTime(start, 0, DateTime(2026, 10, 5, 19, 0)), start);
  });
  test('no reminder once the fire time has passed', () {
    expect(ReminderTiming.fireTime(start, 15, DateTime(2026, 10, 5, 19, 50)), isNull);
    expect(ReminderTiming.fireTime(start, 0, DateTime(2026, 10, 5, 20, 5)), isNull);
  });
  test('labels', () {
    expect(ReminderTiming.label(null), 'Not selected');
    expect(ReminderTiming.label(0), 'When it starts');
    expect(ReminderTiming.label(15), '15 min before');
  });
  test('one reminder per channel + start; ids are stable and positive', () {
    final a = ProgramReminder(channelUrl: 'http://x/1.ts', channelTitle: 'One', programTitle: 'News', start: start);
    final b = ProgramReminder(channelUrl: 'http://x/1.ts', channelTitle: 'One', programTitle: 'News (renamed)', start: start);
    expect(a.key, b.key);
    expect(a.notificationId, b.notificationId);
    expect(a.notificationId >= 0, isTrue);
  });
  test('reminders survive a save/load round trip', () {
    final a = ProgramReminder(channelUrl: 'http://x/1.ts', channelTitle: 'One', programTitle: 'News', start: start);
    final back = ProgramReminder.fromJson(a.toJson())!;
    expect(back.key, a.key);
    expect(back.programTitle, 'News');
    expect(ProgramReminder.fromJson({'start': 'garbage'}), isNull);
  });
}
