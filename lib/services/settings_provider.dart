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

  Future<void> setDeveloperMode(bool enabled) async {
    state = state.copyWith(developerModeEnabled: enabled);
    await _save();
  }

  Future<void> addReminder(TimeOfDay time, {String? taskId}) async {
    final updated = [
      ...state.reminders,
      ReminderTime(
        hour: time.hour,
        minute: time.minute,
        enabled: true,
        taskId: taskId,
      ),
    ];
    state = state.copyWith(reminders: updated);
    await _save();
  }

  Future<void> toggleReminder(int index, bool enabled) async {
    if (index < 0 || index >= state.reminders.length) return;
    final updated = [
      for (int i = 0; i < state.reminders.length; i++)
        if (i == index) state.reminders[i].copyWith(enabled: enabled) else state.reminders[i],
    ];
    state = state.copyWith(reminders: updated);
    await _save();
  }

  Future<void> updateReminder(
    int index, {
    TimeOfDay? time,
    String? taskId,
    bool clearTaskId = false,
  }) async {
    if (index < 0 || index >= state.reminders.length) return;
    final updated = [
      for (int i = 0; i < state.reminders.length; i++)
        if (i == index)
          state.reminders[i].copyWith(
            hour: time?.hour,
            minute: time?.minute,
            taskId: taskId,
            clearTaskId: clearTaskId,
          )
        else
          state.reminders[i],
    ];
    state = state.copyWith(reminders: updated);
    await _save();
  }

  Future<void> removeReminder(int index) async {
    if (index < 0 || index >= state.reminders.length) return;
    final updated = [
      for (int i = 0; i < state.reminders.length; i++)
        if (i != index) state.reminders[i],
    ];
    state = state.copyWith(reminders: updated);
    await _save();
  }

  Future<void> _save() async {
    await StorageManager.saveData(_storageKey, jsonEncode(state.toMap()));
  }
}
