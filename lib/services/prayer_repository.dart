import 'dart:convert';

import '../models/prayer_item.dart';
import 'date_utils.dart';
import 'store_manager.dart';

/// Sync-ready contract for persisting per-day prayer logs and Sunnah config.
abstract class PrayerRepository {
  Future<List<PrayerSunnahConfig>> loadConfig();
  Future<void> saveConfig(List<PrayerSunnahConfig> config);
  Future<DailyPrayerLog> loadLog(
    DateTime date, {
    List<PrayerSunnahConfig>? config,
  });
  Future<void> saveLog(DailyPrayerLog log);
  Future<Map<String, DailyPrayerLog>> loadLogsInRange(
    DateTime start,
    DateTime end,
  );
}

/// Local [SharedPreferences]-backed implementation of [PrayerRepository].
/// Keeps backward compatibility with `prayers_YYYY-MM-DD` keys and avoids
/// persisting empty days until the user actually interacts.
class LocalPrayerRepository implements PrayerRepository {
  static const String _configKey = 'prayer_sunnah_config_v1';
  static String _keyFor(String dateKey) => 'prayers_$dateKey';

  @override
  Future<List<PrayerSunnahConfig>> loadConfig() async {
    final raw = await StorageManager.readData(_configKey);
    if (raw is String && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list
          .map(
            (e) => PrayerSunnahConfig.fromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      if (parsed.length == 5) return parsed;
    }
    return PrayerSunnahConfig.muakkadahDefaults;
  }

  @override
  Future<void> saveConfig(List<PrayerSunnahConfig> config) async {
    final raw = jsonEncode(config.map((c) => c.toMap()).toList());
    await StorageManager.saveData(_configKey, raw);
  }

  @override
  Future<DailyPrayerLog> loadLog(
    DateTime date, {
    List<PrayerSunnahConfig>? config,
  }) async {
    final dateKey = formatDateKey(normalizeDate(date));
    final activeConfig = config ?? await loadConfig();
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
      prayers: DailyPrayerLog.defaultPrayers(activeConfig),
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
