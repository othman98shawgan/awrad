import 'dart:convert';

import '../models/prayer_item.dart';
import 'date_utils.dart';
import 'store_manager.dart';

/// Sync-ready contract for persisting per-day prayer logs and Sunnah config.
abstract class PrayerRepository {
  Future<List<PrayerSunnahConfig>> loadConfig();
  Future<void> saveConfig(List<PrayerSunnahConfig> config);
  DailyPrayerLog? getCachedLog(DateTime date) => null;
  bool hasCachedLog(DateTime date) => false;
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

  List<PrayerSunnahConfig>? _configCache;
  // Maps dateKey -> persisted log (or null if known to have no persisted log).
  final Map<String, DailyPrayerLog?> _logCache = {};

  @override
  DailyPrayerLog? getCachedLog(DateTime date) {
    final dateKey = formatDateKey(normalizeDate(date));
    return _logCache[dateKey];
  }

  @override
  bool hasCachedLog(DateTime date) {
    final dateKey = formatDateKey(normalizeDate(date));
    return _logCache.containsKey(dateKey);
  }

  @override
  Future<List<PrayerSunnahConfig>> loadConfig() async {
    if (_configCache != null) return _configCache!;
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
      if (parsed.length == 5) {
        _configCache = parsed;
        return parsed;
      }
    }
    _configCache = PrayerSunnahConfig.muakkadahDefaults;
    return _configCache!;
  }

  @override
  Future<void> saveConfig(List<PrayerSunnahConfig> config) async {
    _configCache = config;
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
    if (_logCache.containsKey(dateKey)) {
      final cached = _logCache[dateKey];
      if (cached != null) return cached;
      return DailyPrayerLog(
        dateKey: dateKey,
        prayers: DailyPrayerLog.defaultPrayers(activeConfig),
      );
    }

    final raw = await StorageManager.readData(_keyFor(dateKey));
    if (raw is String && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List<dynamic>;
      final items = list
          .map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (items.isNotEmpty) {
        final log = DailyPrayerLog(dateKey: dateKey, prayers: items);
        _logCache[dateKey] = log;
        return log;
      }
    }
    _logCache[dateKey] = null;
    return DailyPrayerLog(
      dateKey: dateKey,
      prayers: DailyPrayerLog.defaultPrayers(activeConfig),
    );
  }

  @override
  Future<void> saveLog(DailyPrayerLog log) async {
    _logCache[log.dateKey] = log;
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
      if (_logCache.containsKey(dateKey)) {
        final cached = _logCache[dateKey];
        if (cached != null) result[dateKey] = cached;
        continue;
      }

      final raw = await StorageManager.readData(_keyFor(dateKey));
      if (raw is String && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final items = list
            .map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
        if (items.isNotEmpty) {
          final log = DailyPrayerLog(dateKey: dateKey, prayers: items);
          _logCache[dateKey] = log;
          result[dateKey] = log;
          continue;
        }
      }
      _logCache[dateKey] = null;
    }
    return result;
  }
}
