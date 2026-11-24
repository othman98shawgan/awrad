import 'dart:convert';

import '../models/prayer_item.dart';
import 'date_utils.dart';
import 'store_manager.dart';

/// Sync-ready contract for persisting per-day prayer logs.
abstract class PrayerRepository {
  Future<DailyPrayerLog> loadLog(DateTime date);
  Future<void> saveLog(DailyPrayerLog log);
  Future<Map<String, DailyPrayerLog>> loadLogsInRange(DateTime start, DateTime end);
}

/// Local [SharedPreferences]-backed implementation of [PrayerRepository].
/// Keeps backward compatibility with `prayers_YYYY-MM-DD` keys and avoids
/// persisting empty days until the user actually interacts.
class LocalPrayerRepository implements PrayerRepository {
  static String _keyFor(String dateKey) => 'prayers_$dateKey';

  @override
  Future<DailyPrayerLog> loadLog(DateTime date) async {
    final dateKey = formatDateKey(normalizeDate(date));
    final raw = await StorageManager.readData(_keyFor(dateKey));
    if (raw is String && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (items.isNotEmpty) {
        return DailyPrayerLog(dateKey: dateKey, prayers: items);
      }
    }
    return DailyPrayerLog(
      dateKey: dateKey,
      prayers: DailyPrayerLog.defaultPrayers(),
    );
  }

  @override
  Future<void> saveLog(DailyPrayerLog log) async {
    final raw = jsonEncode(log.prayers.map((p) => p.toMap()).toList());
    await StorageManager.saveData(_keyFor(log.dateKey), raw);
  }

  @override
  Future<Map<String, DailyPrayerLog>> loadLogsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final result = <String, DailyPrayerLog>{};
    for (final date in datesInRange(start, end)) {
      final dateKey = formatDateKey(date);
      final raw = await StorageManager.readData(_keyFor(dateKey));
      if (raw is String && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final items = list
            .map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (items.isNotEmpty) {
          result[dateKey] = DailyPrayerLog(dateKey: dateKey, prayers: items);
        }
      }
    }
    return result;
  }
}
