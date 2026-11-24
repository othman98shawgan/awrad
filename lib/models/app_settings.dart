import 'package:flutter/material.dart';

/// Persisted user preferences for appearance, screen wakelock, and reminders.
class AppSettings {
  final ThemeMode themeMode;
  final bool keepScreenAwake;
  final bool dailyReminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.keepScreenAwake = false,
    this.dailyReminderEnabled = false,
    this.reminderHour = 20,
    this.reminderMinute = 30,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? keepScreenAwake,
    bool? dailyReminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }

  Map<String, dynamic> toMap() => {
        'themeMode': themeMode.name,
        'keepScreenAwake': keepScreenAwake,
        'dailyReminderEnabled': dailyReminderEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    final modeName = map['themeMode'] as String?;
    final mode = ThemeMode.values.firstWhere(
      (e) => e.name == modeName,
      orElse: () => ThemeMode.system,
    );
    return AppSettings(
      themeMode: mode,
      keepScreenAwake: (map['keepScreenAwake'] as bool?) ?? false,
      dailyReminderEnabled: (map['dailyReminderEnabled'] as bool?) ?? false,
      reminderHour: (map['reminderHour'] as num?)?.toInt() ?? 20,
      reminderMinute: (map['reminderMinute'] as num?)?.toInt() ?? 30,
    );
  }
}
