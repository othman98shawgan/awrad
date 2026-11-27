import 'dart:convert';

import '../models/awrad_log.dart';
import '../models/awrad_status.dart';
import '../models/awrad_task.dart';
import '../models/awrad_template.dart';
import 'date_utils.dart';
import 'default_templates.dart';
import 'store_manager.dart';

/// Sync-ready contract for persisting Awrad definitions and per-day logs.
abstract class AwradRepository {
  Future<List<AwradTask>> loadTasks();
  Future<void> saveTasks(List<AwradTask> tasks);
  DailyAwradLog? getCachedLog(DateTime date) => null;
  Future<DailyAwradLog> loadLog(DateTime date);
  Future<void> saveLog(DailyAwradLog log);
  Future<Map<String, DailyAwradLog>> loadLogsInRange(DateTime start, DateTime end);
  Future<Map<String, DailyAwradLog>> loadAllLogs();
  Future<void> replaceAllLogs(Map<String, DailyAwradLog> logs);
  Future<void> mergeLogs(Map<String, DailyAwradLog> logs);
}

/// Local [SharedPreferences]-backed implementation of [AwradRepository].
/// Automatically migrates legacy `tasks_YYYY-MM-DD` records on first load.
class LocalAwradRepository implements AwradRepository {
  static const String _tasksKey = 'awrad_tasks_v1';
  static const String _logPrefix = 'awrad_log_v1_';
  static const String _legacyPrefix = 'tasks_';
  static const String _migratedKey = 'awrad_legacy_migrated_v1';

  final Map<String, DailyAwradLog> _logCache = {};
  bool _migrated = false;

  String _logKeyFor(String dateKey) => '$_logPrefix$dateKey';

  @override
  DailyAwradLog? getCachedLog(DateTime date) {
    final dateKey = formatDateKey(normalizeDate(date));
    return _logCache[dateKey];
  }

  @override
  Future<List<AwradTask>> loadTasks() async {
    await _migrateLegacyDataIfNeeded();

    final raw = await StorageManager.readData(_tasksKey);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final tasks = decoded
            .map((e) => AwradTask.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return tasks;
      } catch (_) {
        // Corrupted JSON falls through to empty list; auto-backup recovery handles it.
      }
    }

    // First-time users start with an empty Awrad list so they can choose a template or add their own.
    return const [];
  }

  @override
  Future<void> saveTasks(List<AwradTask> tasks) async {
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await StorageManager.saveData(_tasksKey, encoded);
  }

  @override
  Future<DailyAwradLog> loadLog(DateTime date) async {
    await _migrateLegacyDataIfNeeded();

    final dateKey = formatDateKey(normalizeDate(date));
    final cached = _logCache[dateKey];
    if (cached != null) return cached;

    final raw = await StorageManager.readData(_logKeyFor(dateKey));
    final DailyAwradLog log;
    if (raw is String && raw.isNotEmpty) {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      log = DailyAwradLog.fromMap(map);
    } else {
      log = DailyAwradLog(dateKey: dateKey);
    }
    _logCache[dateKey] = log;
    return log;
  }

  @override
  Future<void> saveLog(DailyAwradLog log) async {
    _logCache[log.dateKey] = log;
    final encoded = jsonEncode(log.toMap());
    await StorageManager.saveData(_logKeyFor(log.dateKey), encoded);
  }

  @override
  Future<Map<String, DailyAwradLog>> loadLogsInRange(
    DateTime start,
    DateTime end,
  ) async {
    await _migrateLegacyDataIfNeeded();

    final result = <String, DailyAwradLog>{};
    for (final date in datesInRange(start, end)) {
      final dateKey = formatDateKey(date);
      final cached = _logCache[dateKey];
      if (cached != null) {
        if (cached.entries.isNotEmpty) {
          result[dateKey] = cached;
        }
        continue;
      }

      final raw = await StorageManager.readData(_logKeyFor(dateKey));
      if (raw is String && raw.isNotEmpty) {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final parsed = DailyAwradLog.fromMap(map);
        _logCache[dateKey] = parsed;
        result[dateKey] = parsed;
      } else {
        _logCache[dateKey] = DailyAwradLog(dateKey: dateKey);
      }
    }
    return result;
  }

  @override
  Future<Map<String, DailyAwradLog>> loadAllLogs() async {
    await _migrateLegacyDataIfNeeded();

    final keys = await StorageManager.getKeys();
    final logKeys = keys.where((k) => k.startsWith(_logPrefix)).toList()..sort();
    final result = <String, DailyAwradLog>{};
    for (final key in logKeys) {
      final dateKey = key.substring(_logPrefix.length);
      if (parseDateKey(dateKey) == null) continue;
      final cached = _logCache[dateKey];
      if (cached != null) {
        if (cached.entries.isNotEmpty) {
          result[dateKey] = cached;
        }
        continue;
      }
      final raw = await StorageManager.readData(key);
      if (raw is String && raw.isNotEmpty) {
        try {
          final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          final parsed = DailyAwradLog.fromMap(map);
          _logCache[dateKey] = parsed;
          if (parsed.entries.isNotEmpty) {
            result[dateKey] = parsed;
          }
        } catch (_) {
          // Ignore corrupted log entry.
        }
      }
    }
    return result;
  }

  @override
  Future<void> replaceAllLogs(Map<String, DailyAwradLog> logs) async {
    final keys = await StorageManager.getKeys();
    for (final key in keys) {
      if (key.startsWith(_logPrefix)) {
        await StorageManager.deleteData(key);
      }
    }
    _logCache.clear();
    for (final log in logs.values) {
      if (log.entries.isNotEmpty) {
        await saveLog(log);
      }
    }
  }

  @override
  Future<void> mergeLogs(Map<String, DailyAwradLog> logs) async {
    await _migrateLegacyDataIfNeeded();
    for (final entry in logs.entries) {
      final date = parseDateKey(entry.key);
      if (date == null || entry.value.entries.isEmpty) continue;
      final existing = await loadLog(date);
      final mergedEntries = Map<String, AwradTaskEntry>.from(existing.entries);
      var changed = false;
      for (final taskEntry in entry.value.entries.entries) {
        final current = mergedEntries[taskEntry.key];
        if (current == null ||
            taskEntry.value.updatedAt.isAfter(current.updatedAt)) {
          mergedEntries[taskEntry.key] = taskEntry.value;
          changed = true;
        }
      }
      if (changed) {
        await saveLog(
          DailyAwradLog(dateKey: existing.dateKey, entries: mergedEntries),
        );
      }
    }
  }

  /// Converts an [AwradTemplate] into persisted [AwradTask] instances.
  static List<AwradTask> buildTasksFromTemplate(
    AwradTemplate template, {
    int startSortOrder = 0,
    bool everyDayOverride = false,
  }) {
    final now = DateTime.now();
    return List.generate(template.tasks.length, (i) {
      final item = template.tasks[i];
      return AwradTask(
        id: '${template.id}_${i}_${now.microsecondsSinceEpoch}',
        title: item.title,
        category: item.category,
        repeatWeekdays: everyDayOverride ? const {} : item.repeatWeekdays,
        sortOrder: startSortOrder + i,
        note: item.note,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  /// One-time migration from legacy `tasks_YYYY-MM-DD` lists into separated
  /// task definitions (`awrad_tasks_v1`) and daily logs (`awrad_log_v1_YYYY-MM-DD`).
  Future<void> _migrateLegacyDataIfNeeded() async {
    if (_migrated) return;
    final migrated = await StorageManager.readData(_migratedKey);
    if (migrated == true) {
      _migrated = true;
      return;
    }

    final existingV1 = await StorageManager.readData(_tasksKey);
    if (existingV1 is String && existingV1.isNotEmpty) {
      await StorageManager.saveData(_migratedKey, true);
      _migrated = true;
      return;
    }

    final allKeys = await StorageManager.getKeys();
    final legacyKeys = allKeys.where((k) => k.startsWith(_legacyPrefix)).toList()..sort();

    if (legacyKeys.isEmpty) {
      await StorageManager.saveData(_migratedKey, true);
      _migrated = true;
      return;
    }

    final now = DateTime.now();
    final titleToTask = <String, AwradTask>{};
    final orderedTasks = <AwradTask>[];

    // Seed title lookup with default template categories (plus legacy titles)
    // so migrated tasks inherit categories.
    final defaultCategoryByTitle = <String, AwradCategory>{
      'Read Quran': AwradCategory.quran,
      'Fajr prayer in congregation': AwradCategory.prayer,
      'Duha prayer': AwradCategory.sunnah,
      'Morning adhkar': AwradCategory.adhkar,
      'Evening adhkar': AwradCategory.adhkar,
      '200 times istighfar': AwradCategory.adhkar,
      '200 times “La ilaha illa Allah”': AwradCategory.adhkar,
      '200 blessings on the Prophet': AwradCategory.adhkar,
      'Read for half an hour': AwradCategory.knowledge,
      for (final t in DefaultAwradTemplates.dailyEssentials.tasks)
        t.title: t.category,
    };

    for (final key in legacyKeys) {
      final dateKey = key.substring(_legacyPrefix.length);
      if (parseDateKey(dateKey) == null) continue;

      final raw = await StorageManager.readData(key);
      if (raw is! String || raw.isEmpty) continue;

      final decoded = jsonDecode(raw);
      if (decoded is! List) continue;

      final entries = <String, AwradTaskEntry>{};

      for (final item in decoded) {
        if (item is! Map) continue;
        final title = (item['title'] as String?)?.trim();
        if (title == null || title.isEmpty) continue;

        final task = titleToTask.putIfAbsent(title, () {
          final created = AwradTask(
            id: 'migrated_${orderedTasks.length}',
            title: title,
            category: defaultCategoryByTitle[title] ?? AwradCategory.other,
            repeatWeekdays: const {},
            sortOrder: orderedTasks.length,
            createdAt: now,
            updatedAt: now,
          );
          orderedTasks.add(created);
          return created;
        });

        final status = AwradStatus.fromTristate(item['done'] as bool?);
        if (status != AwradStatus.notDone) {
          entries[task.id] = AwradTaskEntry(status: status, updatedAt: now);
        }
      }

      if (entries.isNotEmpty) {
        await saveLog(DailyAwradLog(dateKey: dateKey, entries: entries));
      }
    }

    if (orderedTasks.isNotEmpty) {
      await saveTasks(orderedTasks);
    }

    await StorageManager.saveData(_migratedKey, true);
    _migrated = true;
  }
}
