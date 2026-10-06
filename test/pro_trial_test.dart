import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/services/pro_service.dart';

void main() {
  final start = DateTime(2026, 10, 6, 15);

  test('free week is active for 7 days from the first launch', () {
    expect(ProTrial.isActive(start, start), isTrue);
    expect(ProTrial.isActive(start, start.add(const Duration(days: 6, hours: 23))), isTrue);
    expect(ProTrial.isActive(start, start.add(const Duration(days: 7))), isFalse);
  });

  test('no start date means no trial', () {
    expect(ProTrial.isActive(null, start), isFalse);
    expect(ProTrial.daysLeft(null, start), 0);
  });

  test('setting the clock far back does not keep the trial alive', () {
    expect(ProTrial.isActive(start, start.subtract(const Duration(days: 3))), isFalse);
  });

  test('days left counts partial days up and stops at zero', () {
    expect(ProTrial.daysLeft(start, start), 7);
    expect(ProTrial.daysLeft(start, start.add(const Duration(days: 6, hours: 1))), 1);
    expect(ProTrial.daysLeft(start, start.add(const Duration(days: 9))), 0);
    expect(ProTrial.label(1), 'Free Pro week: last day');
    expect(ProTrial.label(5), 'Free Pro week: 5 days left');
  });
}
