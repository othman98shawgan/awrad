import 'dart:io';

import 'package:awrad/models/awrad_backup.dart';
import 'package:awrad/models/awrad_log.dart';
import 'package:awrad/models/awrad_status.dart';
import 'package:awrad/models/awrad_task.dart';
import 'package:awrad/models/prayer_item.dart';
import 'package:awrad/services/awrad_provider.dart';
import 'package:awrad/services/awrad_repository.dart';
import 'package:awrad/services/backup_provider.dart';
import 'package:awrad/services/backup_service.dart';
import 'package:awrad/services/prayer_provider.dart';
import 'package:awrad/services/prayer_repository.dart';
import 'package:awrad/ui/pages/settings_page.dart';
import 'package:awrad/ui/theme/app_theme.dart';
import 'package:awrad/ui/widgets/backup_restore_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late LocalAwradRepository awradRepo;
  late LocalPrayerRepository prayerRepo;
  late BackupService backupService;

  final now = DateTime(2026, 11, 27, 7, 0);

  AwradTask makeTask(
    String id,
    String title, {
    int sortOrder = 0,
    bool isArchived = false,
    DateTime? updatedAt,
  }) {
    return AwradTask(
      id: id,
      title: title,
      category: AwradCategory.adhkar,
      repeatWeekdays: const {},
      sortOrder: sortOrder,
      isArchived: isArchived,
      createdAt: now,
      updatedAt: updatedAt ?? now,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('awrad_backup_test_');
    awradRepo = LocalAwradRepository();
    prayerRepo = LocalPrayerRepository();
    backupService = BackupService(
      awradRepo: awradRepo,
      prayerRepo: prayerRepo,
      autoBackupDirProvider: () async => tempDir,
      exportDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    backupService.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AwradBackup serialization', () {
    test('awradOnly round-trips tasks without logs', () {
      final backup = AwradBackup(
        type: BackupType.awradOnly,
        createdAt: now,
        tasks: [makeTask('t1', 'Morning Adhkar', sortOrder: 0)],
      );

      final parsed = AwradBackup.fromJson(backup.toJson());
      expect(parsed.type, BackupType.awradOnly);
      expect(parsed.tasks.length, 1);
      expect(parsed.tasks.first.title, 'Morning Adhkar');
      expect(parsed.awradLogs, isEmpty);
      expect(parsed.prayerLogs, isEmpty);
    });

    test('fullBackup round-trips tasks, awradLogs, and prayerLogs', () {
      final backup = AwradBackup(
        type: BackupType.fullBackup,
        createdAt: now,
        tasks: [makeTask('t1', 'Read Quran')],
        awradLogs: {
          '2026-11-27': DailyAwradLog(
            dateKey: '2026-11-27',
            entries: {
              't1': AwradTaskEntry(status: AwradStatus.done, updatedAt: now),
            },
          ),
        },
        prayerLogs: {
          '2026-11-27': const DailyPrayerLog(
            dateKey: '2026-11-27',
            prayers: [
              PrayerItem(
                name: 'Fajr',
                fard: 2,
                beforeSunnah: 2,
                sunnah: 0,
                fardDone: true,
              ),
            ],
          ),
        },
      );

      final parsed = AwradBackup.fromJson(backup.toJson(pretty: true));
      expect(parsed.type, BackupType.fullBackup);
      expect(parsed.tasks.length, 1);
      expect(parsed.awradLogs['2026-11-27']?.statusFor('t1'), AwradStatus.done);
      expect(
        parsed.prayerLogs['2026-11-27']?.prayers.first.fardDone,
        isTrue,
      );
    });

    test('rejects invalid JSON or unsupported schemaVersion', () {
      expect(() => AwradBackup.fromJson('[]'), throwsFormatException);
      expect(
        () => AwradBackup.fromJson('{"schemaVersion": 99, "type": "awrad_only", "tasks": []}'),
        throwsFormatException,
      );
      expect(
        () => AwradBackup.fromJson('{"schemaVersion": 1, "type": "unknown", "tasks": []}'),
        throwsFormatException,
      );
    });
  });

  group('BackupService export & import', () {
    test('awradOnly export excludes archived tasks and reindexes', () async {
      await awradRepo.saveTasks([
        makeTask('t1', 'Active 1', sortOrder: 2),
        makeTask('t2', 'Archived', sortOrder: 3, isArchived: true),
        makeTask('t3', 'Active 2', sortOrder: 5),
      ]);

      final backup = await backupService.buildBackup(type: BackupType.awradOnly);
      expect(backup.tasks.map((t) => t.title).toList(), ['Active 1', 'Active 2']);
      expect(backup.tasks.map((t) => t.sortOrder).toList(), [0, 1]);
      expect(backup.awradLogs, isEmpty);
      expect(backup.prayerLogs, isEmpty);
    });

    test('importing awradOnly in merge mode skips duplicate titles', () async {
      await awradRepo.saveTasks([makeTask('t1', 'Morning Adhkar', sortOrder: 0)]);
      await awradRepo.saveLog(
        DailyAwradLog(
          dateKey: '2026-11-27',
          entries: {
            't1': AwradTaskEntry(status: AwradStatus.done, updatedAt: now),
          },
        ),
      );

      final friendTemplate = AwradBackup(
        type: BackupType.awradOnly,
        createdAt: now,
        tasks: [
          makeTask('f1', '  morning adhkar ', sortOrder: 0),
          makeTask('f2', 'Evening Adhkar', sortOrder: 1),
        ],
      );

      await backupService.importBackup(
        friendTemplate,
        mode: BackupImportMode.merge,
      );

      final tasks = await awradRepo.loadTasks();
      expect(tasks.map((t) => t.title).toList(), [
        'Morning Adhkar',
        'Evening Adhkar',
      ]);
      final log = await awradRepo.loadLog(DateTime(2026, 11, 27));
      expect(log.statusFor('t1'), AwradStatus.done);
    });

    test('importing fullBackup in replace mode restores tasks and logs', () async {
      await awradRepo.saveTasks([makeTask('old', 'Old Task')]);

      final full = AwradBackup(
        type: BackupType.fullBackup,
        createdAt: now,
        tasks: [makeTask('new1', 'Restored Task')],
        awradLogs: {
          '2026-11-26': DailyAwradLog(
            dateKey: '2026-11-26',
            entries: {
              'new1': AwradTaskEntry(status: AwradStatus.halfDone, updatedAt: now),
            },
          ),
        },
        prayerLogs: {
          '2026-11-26': const DailyPrayerLog(
            dateKey: '2026-11-26',
            prayers: [
              PrayerItem(name: 'Fajr', fard: 2, sunnah: 0, fardDone: true),
            ],
          ),
        },
      );

      await backupService.importBackup(full, mode: BackupImportMode.replace);

      final tasks = await awradRepo.loadTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Restored Task');

      final awradLogs = await awradRepo.loadAllLogs();
      expect(awradLogs['2026-11-26']?.statusFor('new1'), AwradStatus.halfDone);

      final prayerLogs = await prayerRepo.loadAllLogs();
      expect(prayerLogs['2026-11-26']?.prayers.first.fardDone, isTrue);
    });
  });

  group('Auto-backup & startup recovery', () {
    test('saves auto-backup, avoids overwriting with empty, and recovers', () async {
      await awradRepo.saveTasks([makeTask('t1', 'Daily Wird')]);
      await awradRepo.saveLog(
        DailyAwradLog(
          dateKey: '2026-11-27',
          entries: {
            't1': AwradTaskEntry(status: AwradStatus.done, updatedAt: now),
          },
        ),
      );

      await backupService.saveAutoBackup();
      final info = await backupService.getAutoBackupInfo();
      expect(info, isNotNull);
      expect(info!.taskCount, 1);
      expect(info.awradLogDays, 1);

      // While storage has data, startup recovery should not prompt.
      expect(await backupService.checkStartupRecovery(), isNull);

      // Simulate wiped SharedPreferences.
      SharedPreferences.setMockInitialValues({});
      final freshAwradRepo = LocalAwradRepository();
      final freshPrayerRepo = LocalPrayerRepository();
      final freshService = BackupService(
        awradRepo: freshAwradRepo,
        prayerRepo: freshPrayerRepo,
        autoBackupDirProvider: () async => tempDir,
        exportDirProvider: () async => tempDir,
      );

      // Saving auto-backup when storage is empty must NOT wipe existing backup.
      await freshService.saveAutoBackup();

      final recovered = await freshService.checkStartupRecovery();
      expect(recovered, isNotNull);
      expect(recovered!.tasks.first.title, 'Daily Wird');
      freshService.dispose();
    });

    test('falls back to .prev.json when primary auto-backup is corrupted', () async {
      await awradRepo.saveTasks([makeTask('t1', 'First')]);
      await backupService.saveAutoBackup();

      await awradRepo.saveTasks([makeTask('t1', 'Second')]);
      await backupService.saveAutoBackup();

      final primary = File('${tempDir.path}/awrad_auto_backup.json');
      await primary.writeAsString('{corrupted json');

      final loaded = await backupService.loadAutoBackup();
      expect(loaded, isNotNull);
      expect(loaded!.tasks.first.title, 'First');
    });
  });

  group('Backup & Restore UI', () {
    testWidgets('SettingsPage shows Backup & Restore and opens export sheet',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            awradRepositoryProvider.overrideWithValue(awradRepo),
            prayerRepositoryProvider.overrideWithValue(prayerRepo),
            backupServiceProvider.overrideWithValue(backupService),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: SettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Save / Export Backup'),
        200,
      );
      expect(find.text('Save / Export Backup'), findsOneWidget);
      expect(find.text('Import from File'), findsOneWidget);
      expect(find.text('Local Auto-Backup'), findsOneWidget);

      await tester.tap(find.text('Save / Export Backup'));
      await tester.pumpAndSettle();

      expect(find.text('Awrad List Only'), findsOneWidget);
      expect(find.text('Full Backup (Awrad & Progress)'), findsOneWidget);
    });

    testWidgets('Startup recovery dialog restores backup when confirmed',
        (tester) async {
      final recoveredBackup = AwradBackup(
        type: BackupType.fullBackup,
        createdAt: now,
        tasks: [makeTask('r1', 'Recovered Wird')],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            awradRepositoryProvider.overrideWithValue(awradRepo),
            prayerRepositoryProvider.overrideWithValue(prayerRepo),
            backupServiceProvider.overrideWithValue(backupService),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showStartupRecoveryDialog(
                      context,
                      ref,
                      recoveredBackup,
                    ),
                    child: const Text('Trigger'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Backup Found'), findsOneWidget);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      final tasks = await awradRepo.loadTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Recovered Wird');
    });
  });
}
