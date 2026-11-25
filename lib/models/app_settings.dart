import 'package:flutter/material.dart';

/// A single daily reminder entry with an on/off toggle and time of day.
class ReminderTime {
  final int hour;
  final int minute;
  final bool enabled;

  const ReminderTime({
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  ReminderTime copyWith({
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return ReminderTime(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory ReminderTime.fromMap(Map<String, dynamic> map) {
    return ReminderTime(
      hour: (map['hour'] as num?)?.toInt() ?? 20,
      minute: (map['minute'] as num?)?.toInt() ?? 30,
      enabled: (map['enabled'] as bool?) ?? true,
    );
  }
}

/// Persisted user preferences for appearance, screen wakelock, and reminders.
class AppSettings {
  final ThemeMode themeMode;
  final bool keepScreenAwake;
  final List<ReminderTime> reminders;
  final bool developerModeEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.keepScreenAwake = false,
    this.reminders = const [],
    this.developerModeEnabled = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? keepScreenAwake,
    List<ReminderTime>? reminders,
    bool? developerModeEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      reminders: reminders ?? this.reminders,
      developerModeEnabled: developerModeEnabled ?? this.developerModeEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode.name,
        'keepScreenAwake': keepScreenAwake,
        'reminders': reminders.map((r) => r.toMap()).toList(),
        'developerModeEnabled': developerModeEnabled,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final modeName = map['themeMode'] as String?;
    final mode = ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.system,
    );

    final rawReminders = map['reminders'];
    List<ReminderTime> parsedReminders;
    if (rawReminders is List) {
      parsedReminders = rawReminders
          .whereType<Map>()
          .map((e) => ReminderTime.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } else if (map['dailyReminderEnabled'] == true) {
      parsedReminders = [
        ReminderTime(
          hour: (map['reminderHour'] as num?)?.toInt() ?? 20,
          minute: (map['reminderMinute'] as num?)?.toInt() ?? 30,
          enabled: true,
        ),
      ];
    } else {
      parsedReminders = const [];
    }

    return AppSettings(
      themeMode: mode,
      keepScreenAwake: (map['keepScreenAwake'] as bool?) ?? false,
      reminders: parsedReminders,
      developerModeEnabled: (map['developerModeEnabled'] as bool?) ?? false,
    );
  }
}
