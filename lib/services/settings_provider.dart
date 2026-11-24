import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import 'store_manager.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _storageKey = 'app_settings_v1';

  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final raw = await StorageManager.readData(_storageKey);
    if (raw is String && raw.isNotEmpty) {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (!mounted) return;
      state = AppSettings.fromMap(map);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    state = state.copyWith(keepScreenAwake: enabled);
    await _save();
  }

  Future<void> setDailyReminder({
    bool? enabled,
    int? hour,
    int? minute,
  }) async {
    state = state.copyWith(
      dailyReminderEnabled: enabled,
      reminderHour: hour,
      reminderMinute: minute,
    );
    await _save();
  }

  Future<void> _save() async {
    await StorageManager.saveData(_storageKey, jsonEncode(state.toMap()));
  }
}
