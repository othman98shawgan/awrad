import 'package:awrad/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
  });

  test('computeNextTrigger schedules today when time is in the future', () {
    final utc = tz.UTC;
    final now = DateTime.utc(2026, 11, 25, 14, 0);
    final trigger = NotificationService.computeNextTrigger(
      location: utc,
      hour: 20,
      minute: 30,
      skipToday: false,
      now: now,
    );

    expect(trigger.year, 2026);
    expect(trigger.month, 11);
    expect(trigger.day, 25);
    expect(trigger.hour, 20);
    expect(trigger.minute, 30);
  });

  test('computeNextTrigger skips to tomorrow when time passed or all tasks done',
      () {
    final utc = tz.UTC;
    final nowBeforeReminder = DateTime.utc(2026, 11, 25, 14, 0);
    final skippedForCompletion = NotificationService.computeNextTrigger(
      location: utc,
      hour: 20,
      minute: 30,
      skipToday: true,
      now: nowBeforeReminder,
    );
    expect(skippedForCompletion.day, 26);

    final nowAfterReminder = DateTime.utc(2026, 11, 25, 21, 0);
    final nextDay = NotificationService.computeNextTrigger(
      location: utc,
      hour: 20,
      minute: 30,
      skipToday: false,
      now: nowAfterReminder,
    );
    expect(nextDay.day, 26);
  });
}
