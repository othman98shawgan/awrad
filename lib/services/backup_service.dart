import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/awrad_backup.dart';
import '../models/awrad_task.dart';
import 'awrad_repository.dart';
import 'date_utils.dart';
import 'prayer_repository.dart';

/// Handles automatic local rolling backups as well as manual JSON export and
/// import for device migration or sharing Awrad templates.
class BackupService {
  static const String _autoBackupFileName = 'awrad_auto_backup.json';
  static const String _autoBackupPrevFileName = 'awrad_auto_backup.prev.json';
  static const String _autoBackupTmpFileName = 'awrad_auto_backup.tmp.json';

  final AwradRepository _awradRepo;
  final PrayerRepository _prayerRepo;
  final Future<Directory> Function() _autoBackupDirProvider;
  final Future<Directory> Function() _exportDirProvider;
  final VoidCallback? _onAutoBackupSaved;

  Timer? _debounceTimer;
  bool _savingAutoBackup = false;
  bool _pendingAutoBackup = false;

  BackupService({
    required AwradRepository awradRepo,
    required PrayerRepository prayerRepo,
    Future<Directory> Function()? autoBackupDirProvider,
    Future<Directory> Function()? exportDirProvider,
    VoidCallback? onAutoBackupSaved,
  })  : _awradRepo = awradRepo,
        _prayerRepo = prayerRepo,
        _autoBackupDirProvider =
            autoBackupDirProvider ?? getApplicationSupportDirectory,
        _exportDirProvider = exportDirProvider ?? getTemporaryDirectory,
        _onAutoBackupSaved = onAutoBackupSaved;

  void dispose() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Builds an [AwradBackup] snapshot from current local repositories.
  Future<AwradBackup> buildBackup({required BackupType type}) async {
    final tasks = await _awradRepo.loadTasks();
    final now = DateTime.now();

    if (type == BackupType.awradOnly) {
      final activeTasks = tasks.where((t) => !t.isArchived).toList();
      final reindexed = List.generate(
        activeTasks.length,
        (i) => activeTasks[i].copyWith(sortOrder: i),
      );
      return AwradBackup(
        type: BackupType.awradOnly,
        createdAt: now,
        tasks: reindexed,
      );
    }

    final awradLogs = await _awradRepo.loadAllLogs();
    final prayerLogs = await _prayerRepo.loadAllLogs();
    return AwradBackup(
      type: BackupType.fullBackup,
      createdAt: now,
      tasks: tasks,
      awradLogs: awradLogs,
      prayerLogs: prayerLogs,
    );
  }

  String suggestedFileName(BackupType type, [DateTime? now]) {
    final dateKey = formatDateKey(normalizeDate(now ?? DateTime.now()));
    return type == BackupType.awradOnly
        ? 'awrad-template-$dateKey.json'
        : 'awrad-backup-$dateKey.json';
  }

  /// Writes a shareable JSON export file to a temporary directory.
  Future<File> writeExportFile(BackupType type) async {
    final backup = await buildBackup(type: type);
    final dir = await _exportDirProvider();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}/${suggestedFileName(type)}');
    await file.writeAsString(backup.toJson(pretty: true), flush: true);
    return file;
  }

  /// Parses and validates a raw JSON string into an [AwradBackup].
  AwradBackup parseBackupJson(String rawJson) {
    return AwradBackup.fromJson(rawJson);
  }

  /// Imports an [AwradBackup] into local storage using [mode].
  Future<void> importBackup(
    AwradBackup backup, {
    required BackupImportMode mode,
  }) async {
    if (backup.type == BackupType.awradOnly) {
      await _importAwradOnly(backup.tasks, mode: mode);
      return;
    }

    if (mode == BackupImportMode.replace) {
      final reindexed = _reindexTasks(backup.tasks);
      await _awradRepo.saveTasks(reindexed);
      await _awradRepo.replaceAllLogs(backup.awradLogs);
      await _prayerRepo.replaceAllLogs(backup.prayerLogs);
    } else {
      await _mergeFullTasks(backup.tasks);
      await _awradRepo.mergeLogs(backup.awradLogs);
      await _prayerRepo.mergeLogs(backup.prayerLogs);
    }
  }

  Future<void> _importAwradOnly(
    List<AwradTask> incoming, {
    required BackupImportMode mode,
  }) async {
    final now = DateTime.now();
    final baseMicros = now.microsecondsSinceEpoch;

    if (mode == BackupImportMode.replace) {
      final fresh = List.generate(incoming.length, (i) {
        final t = incoming[i];
        return t.copyWith(
          id: 'imported_${i}_$baseMicros',
          sortOrder: i,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        );
      });
      await _awradRepo.saveTasks(fresh);
      return;
    }

    final existing = await _awradRepo.loadTasks();
    final existingTitles = existing
        .where((t) => !t.isArchived)
        .map((t) => t.title.toLowerCase().trim())
        .toSet();

    final added = <AwradTask>[];
    for (var i = 0; i < incoming.length; i++) {
      final t = incoming[i];
      final normalizedTitle = t.title.toLowerCase().trim();
      if (normalizedTitle.isEmpty || existingTitles.contains(normalizedTitle)) {
        continue;
      }
      existingTitles.add(normalizedTitle);
      added.add(
        t.copyWith(
          id: 'imported_${i}_$baseMicros',
          sortOrder: existing.length + added.length,
          isArchived: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (added.isNotEmpty) {
      await _awradRepo.saveTasks([...existing, ...added]);
    }
  }

  Future<void> _mergeFullTasks(List<AwradTask> incoming) async {
    final existing = await _awradRepo.loadTasks();
    final byId = {for (final t in existing) t.id: t};
    final result = [...existing];

    for (final task in incoming) {
      final current = byId[task.id];
      if (current == null) {
        result.add(task);
      } else if (task.updatedAt.isAfter(current.updatedAt)) {
        final idx = result.indexWhere((t) => t.id == task.id);
        if (idx != -1) {
          result[idx] = task;
        }
      }
    }

    await _awradRepo.saveTasks(_reindexTasks(result));
  }

  List<AwradTask> _reindexTasks(List<AwradTask> tasks) {
    final sorted = [...tasks]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.generate(
      sorted.length,
      (i) => sorted[i].copyWith(sortOrder: i),
    );
  }

  /// Schedules a debounced auto-backup after data mutations.
  void scheduleAutoBackup({Duration delay = const Duration(seconds: 2)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      saveAutoBackup();
    });
  }

  /// Immediately flushes any pending auto-backup (e.g. on app pause).
  Future<void> flushAutoBackup() async {
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel();
      _debounceTimer = null;
      await saveAutoBackup();
    }
  }

  /// Writes the rolling local auto-backup file atomically.
  /// Skips overwriting an existing backup if current local storage is empty.
  Future<void> saveAutoBackup() async {
    if (_savingAutoBackup) {
      _pendingAutoBackup = true;
      return;
    }
    _savingAutoBackup = true;
    try {
      final backup = await buildBackup(type: BackupType.fullBackup);
      if (backup.isEmpty) return;

      final dir = await _autoBackupDirProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final primary = File('${dir.path}/$_autoBackupFileName');
      final prev = File('${dir.path}/$_autoBackupPrevFileName');
      final tmp = File('${dir.path}/$_autoBackupTmpFileName');

      await tmp.writeAsString(backup.toJson(), flush: true);

      if (await primary.exists()) {
        await primary.copy(prev.path);
      }
      await tmp.rename(primary.path);
      _onAutoBackupSaved?.call();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BackupService.saveAutoBackup failed: $e');
      }
    } finally {
      _savingAutoBackup = false;
      if (_pendingAutoBackup) {
        _pendingAutoBackup = false;
        unawaited(saveAutoBackup());
      }
    }
  }

  /// Loads the latest valid auto-backup, falling back to `.prev.json` if
  /// the primary file is missing or corrupted.
  Future<AwradBackup?> loadAutoBackup() async {
    try {
      final dir = await _autoBackupDirProvider();
      for (final name in [_autoBackupFileName, _autoBackupPrevFileName]) {
        final file = File('${dir.path}/$name');
        if (!await file.exists()) continue;
        try {
          final raw = await file.readAsString();
          if (raw.trim().isEmpty) continue;
          final parsed = AwradBackup.fromJson(raw);
          if (!parsed.isEmpty) return parsed;
        } catch (_) {
          // Try next fallback file.
        }
      }
    } catch (_) {
      // Directory unavailable.
    }
    return null;
  }

  /// Returns metadata about the latest auto-backup if available.
  Future<AutoBackupInfo?> getAutoBackupInfo() async {
    final backup = await loadAutoBackup();
    if (backup == null) return null;
    return AutoBackupInfo(
      createdAt: backup.createdAt,
      taskCount: backup.tasks.where((t) => !t.isArchived).length,
      awradLogDays: backup.awradLogs.length,
      prayerLogDays: backup.prayerLogs.length,
    );
  }

  /// Returns the auto-backup if local storage is currently empty and a
  /// non-empty auto-backup exists on disk (indicating data loss or fresh
  /// restore of the backup file).
  Future<AwradBackup?> checkStartupRecovery() async {
    final tasks = await _awradRepo.loadTasks();
    if (tasks.isNotEmpty) return null;

    final awradLogs = await _awradRepo.loadAllLogs();
    if (awradLogs.isNotEmpty) return null;

    final prayerLogs = await _prayerRepo.loadAllLogs();
    if (prayerLogs.isNotEmpty) return null;

    return loadAutoBackup();
  }
}
