import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

/// Handles scheduling multiple daily Awrad reminders and auto-cancelling
/// today's reminders when all daily tasks are completed.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int reminderIdBase = 1000;
  static const int maxRemindersToClear = 50;
  static const int testNotificationId = 1999;
  static const String channelId = 'awrad_daily_reminders';
  static const String channelName = 'Daily Awrad Reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Pure helper for computing the next trigger timestamp.
  /// If [skipToday] is true (e.g., all today's tasks are already done),
  /// schedules for tomorrow at [hour]:[minute].
  static tz.TZDateTime computeNextTrigger({
    required tz.Location location,
    required int hour,
    required int minute,
    required bool skipToday,
    DateTime? now,
  }) {
    final base = now != null
        ? tz.TZDateTime.from(now, location)
        : tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(
      location,
      base.year,
      base.month,
      base.day,
      hour,
      minute,
    );
    if (skipToday || !scheduled.isAfter(base)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> init() async {
    if (kIsWeb || _initialized) return;

    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

      const androidInit = AndroidInitializationSettings('ic_stat_awrad');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _plugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService init skipped: $e');
      }
    }
  }

  Future<bool> arePermissionsGranted() async {
    if (kIsWeb) return true;
    if (!_initialized) await init();
    if (!_initialized) return true;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        return await androidImpl.areNotificationsEnabled() ?? true;
      }

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final perms = await iosImpl.checkPermissions();
        return perms?.isEnabled ?? true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (!_initialized) await init();
    if (!_initialized) return false;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted =
          await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();

      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final iosGranted = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return (androidGranted ?? true) && (iosGranted ?? true);
    } catch (_) {
      return false;
    }
  }

  NotificationDetails _buildDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Daily reminders for your remaining Awrad tasks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const darwinDetails = DarwinNotificationDetails();
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// Syncs all configured [reminders] with the OS scheduler.
  /// - General reminders (`taskId == null`) skip today when all Awrad are done.
  /// - Wird-specific reminders skip today as soon as that specific Wird is done.
  Future<void> syncReminders({
    required List<ReminderTime> reminders,
    required int remainingAwradCount,
    Map<String, String> taskTitlesById = const {},
    Set<String> doneTaskIds = const {},
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      for (int i = 0; i < maxRemindersToClear; i++) {
        await _plugin.cancel(id: reminderIdBase + i);
      }

      for (int i = 0; i < reminders.length && i < maxRemindersToClear; i++) {
        final reminder = reminders[i];
        if (!reminder.enabled) continue;

        final linkedTitle = reminder.taskId != null
            ? taskTitlesById[reminder.taskId!]
            : null;
        final isSpecificWird = reminder.taskId != null && linkedTitle != null;

        final skipToday = isSpecificWird
            ? doneTaskIds.contains(reminder.taskId)
            : remainingAwradCount == 0;

        final scheduled = computeNextTrigger(
          location: tz.local,
          hour: reminder.hour,
          minute: reminder.minute,
          skipToday: skipToday,
        );

        final body = isSpecificWird
            ? 'Time for: $linkedTitle'
            : (remainingAwradCount > 0
                ? 'You have $remainingAwradCount Awrad remaining today. Tap to open.'
                : 'Time for your daily Awrad.');

        try {
          await _plugin.zonedSchedule(
            id: reminderIdBase + i,
            title: 'Daily Awrad Reminder',
            body: body,
            scheduledDate: scheduled,
            notificationDetails: _buildDetails(),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        } catch (_) {
          await _plugin.zonedSchedule(
            id: reminderIdBase + i,
            title: 'Daily Awrad Reminder',
            body: body,
            scheduledDate: scheduled,
            notificationDetails: _buildDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService sync failed: $e');
      }
    }
  }

  Future<void> sendTestNotification({required int remainingAwradCount}) async {
    if (kIsWeb) return;
    if (!_initialized) await init();
    if (!_initialized) return;

    final body = remainingAwradCount > 0
        ? 'You have $remainingAwradCount Awrad remaining today. Tap to open.'
        : 'All Awrad completed for today!';

    await _plugin.show(
      id: testNotificationId,
      title: 'Daily Awrad Reminder',
      body: body,
      notificationDetails: _buildDetails(),
    );
  }
}
