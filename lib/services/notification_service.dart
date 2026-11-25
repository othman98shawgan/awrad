import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';

/// Handles local daily Awrad reminder scheduling, quick-action responses,
/// and auto-cancellation when all daily tasks are completed.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int dailyReminderId = 1001;
  static const int testNotificationId = 1002;
  static const String channelId = 'awrad_daily_reminders';
  static const String channelName = 'Daily Awrad Reminders';
  static const String markAllDoneActionId = 'mark_all_done';
  static const String darwinCategoryId = 'awrad_reminder_category';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(String? actionId)? _onAction;

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

  Future<void> init({void Function(String? actionId)? onAction}) async {
    _onAction = onAction;
    if (kIsWeb || _initialized) return;

    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            darwinCategoryId,
            actions: [
              DarwinNotificationAction.plain(
                markAllDoneActionId,
                'Mark All Done',
                options: {DarwinNotificationActionOption.foreground},
              ),
            ],
          ),
        ],
      );

      final initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          _onAction?.call(response.actionId);
        },
      );
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService init skipped: $e');
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    if (!_initialized) await init(onAction: _onAction);
    if (!_initialized) return false;

    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final androidGranted =
          await androidImpl?.requestNotificationsPermission();

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
      channelDescription: 'Daily reminder for your remaining Awrad tasks',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          markAllDoneActionId,
          'Mark All Done',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: darwinCategoryId,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  /// Schedules or cancels the daily reminder based on [settings] and
  /// [remainingAwradCount]. When all today's Awrad are complete (`0` left),
  /// today's reminder is cancelled and scheduled for tomorrow instead.
  Future<void> syncDailyReminder({
    required AppSettings settings,
    required int remainingAwradCount,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      await _plugin.cancel(id: dailyReminderId);
      if (!settings.dailyReminderEnabled) return;

      final scheduled = computeNextTrigger(
        location: tz.local,
        hour: settings.reminderHour,
        minute: settings.reminderMinute,
        skipToday: remainingAwradCount == 0,
      );

      final body = remainingAwradCount > 0
          ? 'You have $remainingAwradCount Awrad remaining today.'
          : 'Time for your daily Awrad.';

      await _plugin.zonedSchedule(
        id: dailyReminderId,
        title: 'Daily Awrad Reminder',
        body: body,
        scheduledDate: scheduled,
        notificationDetails: _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService sync failed: $e');
      }
    }
  }

  Future<void> sendTestNotification({required int remainingAwradCount}) async {
    if (kIsWeb) return;
    if (!_initialized) await init(onAction: _onAction);
    if (!_initialized) return;

    final body = remainingAwradCount > 0
        ? 'You have $remainingAwradCount Awrad remaining today.'
        : 'All Awrad completed for today!';

    await _plugin.show(
      id: testNotificationId,
      title: 'Daily Awrad Reminder',
      body: body,
      notificationDetails: _buildDetails(),
    );
  }
}
