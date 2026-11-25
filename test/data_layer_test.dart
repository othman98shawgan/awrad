import 'dart:convert';

import 'package:awrad/models/app_settings.dart';
import 'package:awrad/models/awrad_status.dart';
import 'package:awrad/models/awrad_task.dart';
import 'package:awrad/models/prayer_item.dart';
import 'package:awrad/services/awrad_provider.dart';
import 'package:awrad/services/awrad_repository.dart';
import 'package:awrad/services/date_utils.dart';
import 'package:awrad/services/default_templates.dart';
import 'package:awrad/services/prayer_repository.dart';
import 'package:awrad/services/selected_date_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AwradStatus', () {
    test('cycles notDone -> done -> halfDone -> notDone and computes scores', () {
      expect(AwradStatus.notDone.next(), AwradStatus.done);
      expect(AwradStatus.done.next(), AwradStatus.halfDone);
      expect(AwradStatus.halfDone.next(), AwradStatus.notDone);

      expect(AwradStatus.notDone.score, 0.0);
      expect(AwradStatus.halfDone.score, 0.5);
      expect(AwradStatus.done.score, 1.0);

      expect(AwradStatus.fromTristate(false), AwradStatus.notDone);
      expect(AwradStatus.fromTristate(null), AwradStatus.halfDone);
      expect(AwradStatus.fromTristate(true), AwradStatus.done);
    });
  });

  group('AwradTask', () {
    test('appliesTo respects repeatWeekdays and archive state', () {
      final now = DateTime(2026, 11, 24);
      final mondayThursday = AwradTask(
        id: 't1',
        title: 'Fasting',
        category: AwradCategory.fasting,
        repeatWeekdays: const {DateTime.monday, DateTime.thursday},
        createdAt: now,
        updatedAt: now,
      );

      // 2026-11-23 is Monday, 2026-11-24 is Tuesday, 2026-11-26 is Thursday.
      expect(mondayThursday.appliesTo(DateTime(2026, 11, 23)), isTrue);
      expect(mondayThursday.appliesTo(DateTime(2026, 11, 24)), isFalse);
      expect(mondayThursday.appliesTo(DateTime(2026, 11, 26)), isTrue);

      final archived = mondayThursday.copyWith(isArchived: true);
      expect(archived.appliesTo(DateTime(2026, 11, 23)), isFalse);
    });

    test('round-trips toMap and fromMap', () {
      final now = DateTime(2026, 11, 24, 8, 30);
      final task = AwradTask(
        id: 'id_1',
        title: 'Read Quran',
        category: AwradCategory.quran,
        repeatWeekdays: const {DateTime.friday},
        sortOrder: 2,
        note: 'Surah Al-Kahf',
        createdAt: now,
        updatedAt: now,
      );

      final restored = AwradTask.fromMap(task.toMap());
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.category, AwradCategory.quran);
      expect(restored.repeatWeekdays, {DateTime.friday});
      expect(restored.sortOrder, 2);
      expect(restored.note, 'Surah Al-Kahf');
    });
  });

  group('PrayerItem', () {
    test('accurately computes partial rakahs and tri-state status', () {
      const dhuhr = PrayerItem(
        name: 'Dhuhr',
        fard: 4,
        beforeSunnah: 4,
        sunnah: 4,
      );

      expect(dhuhr.totalRakahs, 12);
      expect(dhuhr.completedRakahs, 0);
      expect(dhuhr.status, AwradStatus.notDone);
      expect(dhuhr.done, false);

      final partial = dhuhr.copyWith(beforeSunnahDone: true);
      expect(partial.completedRakahs, 4);
      expect(partial.status, AwradStatus.halfDone);
      expect(partial.done, isNull);

      final fardOnly = dhuhr.copyWith(fardDone: true);
      expect(fardOnly.completedRakahs, 4);
      expect(fardOnly.status, AwradStatus.done);
      expect(fardOnly.done, true);

      final full = dhuhr.markAll(true);
      expect(full.completedRakahs, 12);
      expect(full.status, AwradStatus.done);
      expect(full.done, true);
    });
  });

  group('LocalAwradRepository & migration', () {
    test('migrates legacy tasks_YYYY-MM-DD entries preserving half-done states', () async {
      SharedPreferences.setMockInitialValues({
        'tasks_2026-11-23': jsonEncode([
          {'title': 'Read Quran', 'done': true},
          {'title': '200 times istighfar', 'done': null},
          {'title': 'Duha prayer', 'done': false},
        ]),
      });

      final repo = LocalAwradRepository();
      final tasks = await repo.loadTasks();
      expect(tasks.length, 3);
      expect(tasks[0].title, 'Read Quran');
      expect(tasks[0].category, AwradCategory.quran);

      final log = await repo.loadLog(DateTime(2026, 11, 23));
      expect(log.statusFor(tasks[0].id), AwradStatus.done);
      expect(log.statusFor(tasks[1].id), AwradStatus.halfDone);
      expect(log.statusFor(tasks[2].id), AwradStatus.notDone);
    });

    test('AwradTasksNotifier supports CRUD, reorder, and template import', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalAwradRepository();
      final notifier = AwradTasksNotifier(repo);
      await notifier.load();

      final initialCount = notifier.state.length;
      expect(initialCount, DefaultAwradTemplates.dailyEssentials.tasks.length);

      await notifier.addTask(
        title: 'Tahajjud',
        category: AwradCategory.sunnah,
      );
      expect(notifier.state.length, initialCount + 1);
      final added = notifier.state.last;
      expect(added.title, 'Tahajjud');

      await notifier.reorderTasks(notifier.state.length - 1, 0);
      expect(notifier.state.first.id, added.id);

      await notifier.deleteTask(added.id);
      expect(notifier.state.length, initialCount);

      await notifier.importTemplate(
        DefaultAwradTemplates.morningEveningAdhkar,
        replace: true,
      );
      expect(
        notifier.state.length,
        DefaultAwradTemplates.morningEveningAdhkar.tasks.length,
      );
    });
  });

  group('LocalPrayerRepository', () {
    test('does not write empty days on load, and persists on save', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalPrayerRepository();
      final date = DateTime(2026, 11, 24);

      final loaded = await repo.loadLog(date);
      expect(loaded.prayers.length, 5);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);

      final updatedPrayers = [
        loaded.prayers.first.copyWith(fardDone: true, inMasjid: true),
        ...loaded.prayers.skip(1),
      ];
      await repo.saveLog(
        DailyPrayerLog(dateKey: formatDateKey(date), prayers: updatedPrayers),
      );

      final reloaded = await repo.loadLog(date);
      expect(reloaded.prayers.first.fardDone, isTrue);
      expect(reloaded.prayers.first.inMasjid, isTrue);
      expect(reloaded.completedRakahs, 2);
    });
  });

  group('SelectedDateNotifier & AppSettings', () {
    test('normalizes dates to midnight', () {
      final notifier = SelectedDateNotifier(DateTime(2026, 11, 24, 15, 45, 30));
      expect(notifier.state, DateTime(2026, 11, 24));

      notifier.stepDays(-1);
      expect(notifier.state, DateTime(2026, 11, 23));
    });

    test('AppSettings serializes themeMode, wakelock, and multiple reminders', () {
      const settings = AppSettings(
        themeMode: ThemeMode.dark,
        keepScreenAwake: true,
        reminders: [
          ReminderTime(hour: 5, minute: 30, note: 'Morning Adhkar'),
          ReminderTime(hour: 21, minute: 15, enabled: false),
        ],
      );
      final restored = AppSettings.fromMap(settings.toMap());
      expect(restored.themeMode, ThemeMode.dark);
      expect(restored.keepScreenAwake, isTrue);
      expect(restored.reminders.length, 2);
      expect(restored.reminders[0].hour, 5);
      expect(restored.reminders[0].minute, 30);
      expect(restored.reminders[0].note, 'Morning Adhkar');
      expect(restored.reminders[1].enabled, isFalse);
    });
  });
}
