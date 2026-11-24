import 'awrad_status.dart';

/// A single task's completion record for a specific day.
class AwradTaskEntry {
  final AwradStatus status;
  final String? note;
  final DateTime updatedAt;

  const AwradTaskEntry({
    required this.status,
    this.note,
    required this.updatedAt,
  });

  AwradTaskEntry copyWith({
    AwradStatus? status,
    String? note,
    bool clearNote = false,
    DateTime? updatedAt,
  }) {
    return AwradTaskEntry(
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'note': note,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AwradTaskEntry.fromMap(Map<String, dynamic> map) {
    return AwradTaskEntry(
      status: AwradStatus.fromJson(map['status'] as String?),
      note: map['note'] as String?,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Stores all Awrad task completion entries for a single calendar date (`YYYY-MM-DD`).
class DailyAwradLog {
  final String dateKey;
  final Map<String, AwradTaskEntry> entries;

  const DailyAwradLog({
    required this.dateKey,
    this.entries = const {},
  });

  AwradStatus statusFor(String taskId) {
    return entries[taskId]?.status ?? AwradStatus.notDone;
  }

  String? noteFor(String taskId) {
    return entries[taskId]?.note;
  }

  DailyAwradLog withEntry(String taskId, AwradTaskEntry entry) {
    final updated = Map<String, AwradTaskEntry>.from(entries);
    if (entry.status == AwradStatus.notDone && (entry.note == null || entry.note!.isEmpty)) {
      updated.remove(taskId);
    } else {
      updated[taskId] = entry;
    }
    return DailyAwradLog(dateKey: dateKey, entries: updated);
  }

  Map<String, dynamic> toMap() => {
        'dateKey': dateKey,
        'entries': entries.map((k, v) => MapEntry(k, v.toMap())),
      };

  factory DailyAwradLog.fromMap(Map<String, dynamic> map) {
    final rawEntries = map['entries'];
    final parsed = <String, AwradTaskEntry>{};
    if (rawEntries is Map) {
      for (final entry in rawEntries.entries) {
        if (entry.value is Map) {
          parsed[entry.key.toString()] =
              AwradTaskEntry.fromMap(Map<String, dynamic>.from(entry.value as Map));
        }
      }
    }
    return DailyAwradLog(
      dateKey: map['dateKey'] as String? ?? '',
      entries: parsed,
    );
  }
}
