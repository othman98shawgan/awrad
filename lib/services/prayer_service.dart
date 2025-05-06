import 'dart:convert';
import 'store_manager.dart';

/// Data model for a single prayer, including an optional "before Sunnah" segment (e.g., Duhr)
class PrayerItem {
  final String name;
  final int fard; // Fard rak‘ahs
  final int beforeSunnah; // Sunnah before Fard (only >0 for Duhr)
  final int sunnah; // Sunnah after Fard
  final int witr; // Witr rak‘ahs (only >0 for Isha)
  bool? done; // true / false / null (partial)
  bool inMasjid;
  bool fardDone;
  bool beforeSunnahDone;
  bool sunnahDone;
  bool witrDone;

  PrayerItem({
    required this.name,
    required this.fard,
    this.beforeSunnah = 0,
    required this.sunnah,
    this.witr = 0,
    this.done = false,
    this.inMasjid = false,
    this.fardDone = false,
    this.beforeSunnahDone = false,
    this.sunnahDone = false,
    this.witrDone = false,
  });

  PrayerItem.fromMap(Map<String, dynamic> m)
      : name = m['name'],
        fard = m['fard'],
        beforeSunnah = m['beforeSunnah'],
        sunnah = m['sunnah'],
        witr = m['witr'],
        done = m['done'],
        inMasjid = m['inMasjid'],
        fardDone = m['fardDone'],
        beforeSunnahDone = m['beforeSunnahDone'],
        sunnahDone = m['sunnahDone'],
        witrDone = m['witrDone'];

  Map<String, dynamic> toMap() => {
        'name': name,
        'fard': fard,
        'beforeSunnah': beforeSunnah,
        'sunnah': sunnah,
        'witr': witr,
        'done': done,
        'inMasjid': inMasjid,
        'fardDone': fardDone,
        'beforeSunnahDone': beforeSunnahDone,
        'sunnahDone': sunnahDone,
        'witrDone': witrDone,
      };
}

/// Handles per-day persistence of prayers
class PrayerService {
  static String _keyFor(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return 'prayers_$y-$m-$d';
  }

  /// Load saved prayers for [date], or return empty list if none.
  static Future<List<PrayerItem>> load(DateTime date) async {
    final raw = await StorageManager.readData(_keyFor(date));
    if (raw is String) {
      final list = jsonDecode(raw) as List;
      return list.map((e) => PrayerItem.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    return [];
  }

  /// Save [items] under the key for [date]
  static void save(DateTime date, List<PrayerItem> items) {
    final raw = jsonEncode(items.map((p) => p.toMap()).toList());
    StorageManager.saveData(_keyFor(date), raw);
  }
}
