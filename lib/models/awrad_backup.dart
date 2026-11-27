import 'dart:convert';

import 'awrad_log.dart';
import 'awrad_task.dart';
import 'prayer_item.dart';

/// Whether an exported JSON file contains only Awrad definitions (for sharing
/// as a template) or a full backup including Awrad and prayer progress.
enum BackupType {
  awradOnly('awrad_only'),
  fullBackup('full_backup');

  final String wireValue;
  const BackupType(this.wireValue);

  static BackupType fromWire(String? value) {
    return BackupType.values.firstWhere(
      (e) => e.wireValue == value,
      orElse: () => BackupType.awradOnly,
    );
  }
}

/// How an imported backup should be applied to existing local data.
enum BackupImportMode {
  merge,
  replace,
}

/// Metadata summary for the rolling local auto-backup file.
class AutoBackupInfo {
  final DateTime createdAt;
  final int taskCount;
  final int awradLogDays;
  final int prayerLogDays;

  const AutoBackupInfo({
    required this.createdAt,
    required this.taskCount,
    required this.awradLogDays,
    required this.prayerLogDays,
  });
}

/// Portable JSON representation of Awrad tasks and (optionally) daily logs.
class AwradBackup {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final BackupType type;
  final DateTime createdAt;
  final List<AwradTask> tasks;
  final Map<String, DailyAwradLog> awradLogs;
  final Map<String, DailyPrayerLog> prayerLogs;

  const AwradBackup({
    this.schemaVersion = currentSchemaVersion,
    required this.type,
    required this.createdAt,
    required this.tasks,
    this.awradLogs = const {},
    this.prayerLogs = const {},
  });

  bool get isEmpty =>
      tasks.isEmpty && awradLogs.isEmpty && prayerLogs.isEmpty;

  Map<String, dynamic> toMap() => {
        'schemaVersion': schemaVersion,
        'type': type.wireValue,
        'createdAt': createdAt.toIso8601String(),
        'tasks': tasks.map((t) => t.toMap()).toList(),
        if (type == BackupType.fullBackup) ...{
          'awradLogs': awradLogs.map((k, v) => MapEntry(k, v.toMap())),
          'prayerLogs': prayerLogs.map(
            (k, v) => MapEntry(k, v.prayers.map((p) => p.toMap()).toList()),
          ),
        },
      };

  String toJson({bool pretty = false}) {
    if (pretty) {
      return const JsonEncoder.withIndent('  ').convert(toMap());
    }
    return jsonEncode(toMap());
  }

  factory AwradBackup.fromMap(Map<String, dynamic> map) {
    final version = (map['schemaVersion'] as num?)?.toInt();
    if (version == null || version < 1) {
      throw const FormatException('Missing or invalid backup schemaVersion.');
    }
    if (version > currentSchemaVersion) {
      throw FormatException(
        'Backup schemaVersion $version is newer than supported ($currentSchemaVersion).',
      );
    }

    final rawType = map['type'] as String?;
    if (rawType != BackupType.awradOnly.wireValue &&
        rawType != BackupType.fullBackup.wireValue) {
      throw const FormatException('Unrecognized backup type.');
    }
    final type = BackupType.fromWire(rawType);

    final rawTasks = map['tasks'];
    if (rawTasks is! List) {
      throw const FormatException('Backup is missing a valid tasks list.');
    }
    final tasks = rawTasks
        .whereType<Map>()
        .map((e) => AwradTask.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final awradLogs = <String, DailyAwradLog>{};
    final rawAwradLogs = map['awradLogs'];
    if (rawAwradLogs is Map) {
      for (final entry in rawAwradLogs.entries) {
        if (entry.value is Map) {
          final logMap = Map<String, dynamic>.from(entry.value as Map);
          logMap.putIfAbsent('dateKey', () => entry.key.toString());
          final parsed = DailyAwradLog.fromMap(logMap);
          if (parsed.entries.isNotEmpty) {
            awradLogs[parsed.dateKey] = parsed;
          }
        }
      }
    }

    final prayerLogs = <String, DailyPrayerLog>{};
    final rawPrayerLogs = map['prayerLogs'];
    if (rawPrayerLogs is Map) {
      for (final entry in rawPrayerLogs.entries) {
        final dateKey = entry.key.toString();
        if (entry.value is List) {
          final items = (entry.value as List)
              .whereType<Map>()
              .map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          if (items.isNotEmpty) {
            prayerLogs[dateKey] = DailyPrayerLog(
              dateKey: dateKey,
              prayers: items,
            );
          }
        }
      }
    }

    return AwradBackup(
      schemaVersion: version,
      type: type,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      tasks: tasks,
      awradLogs: awradLogs,
      prayerLogs: prayerLogs,
    );
  }

  factory AwradBackup.fromJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Backup file must contain a JSON object.');
    }
    return AwradBackup.fromMap(Map<String, dynamic>.from(decoded));
  }
}
