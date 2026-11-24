import 'awrad_status.dart';

/// Data model for a single daily prayer, including optional before-Sunnah (Dhuhr)
/// and Witr (Isha) segments.
class PrayerItem {
  final String name;
  final int fard;
  final int beforeSunnah;
  final int sunnah;
  final int witr;
  final bool inMasjid;
  final bool fardDone;
  final bool beforeSunnahDone;
  final bool sunnahDone;
  final bool witrDone;

  const PrayerItem({
    required this.name,
    required this.fard,
    this.beforeSunnah = 0,
    required this.sunnah,
    this.witr = 0,
    this.inMasjid = false,
    this.fardDone = false,
    this.beforeSunnahDone = false,
    this.sunnahDone = false,
    this.witrDone = false,
  });

  /// Total possible rak‘ahs for this prayer (fard + sunnah + witr).
  int get totalRakahs => fard + beforeSunnah + sunnah + witr;

  /// Accurately sums rak‘ahs for each completed segment (supports partial progress).
  int get completedRakahs =>
      (fardDone ? fard : 0) +
      (beforeSunnah > 0 && beforeSunnahDone ? beforeSunnah : 0) +
      (sunnah > 0 && sunnahDone ? sunnah : 0) +
      (witr > 0 && witrDone ? witr : 0);

  /// Computed tri-state completion status derived from all applicable segments.
  AwradStatus get status {
    final checks = <bool>[
      inMasjid,
      fardDone,
      if (beforeSunnah > 0) beforeSunnahDone,
      if (sunnah > 0) sunnahDone,
      if (witr > 0) witrDone,
    ];
    final all = checks.every((c) => c);
    final any = checks.any((c) => c);
    if (all) return AwradStatus.done;
    if (any) return AwradStatus.halfDone;
    return AwradStatus.notDone;
  }

  /// Tri-state checkbox value (`true` = done, `null` = halfDone, `false` = notDone).
  bool? get done => status.toTristate();

  PrayerItem copyWith({
    String? name,
    int? fard,
    int? beforeSunnah,
    int? sunnah,
    int? witr,
    bool? inMasjid,
    bool? fardDone,
    bool? beforeSunnahDone,
    bool? sunnahDone,
    bool? witrDone,
  }) {
    return PrayerItem(
      name: name ?? this.name,
      fard: fard ?? this.fard,
      beforeSunnah: beforeSunnah ?? this.beforeSunnah,
      sunnah: sunnah ?? this.sunnah,
      witr: witr ?? this.witr,
      inMasjid: inMasjid ?? this.inMasjid,
      fardDone: fardDone ?? this.fardDone,
      beforeSunnahDone: beforeSunnahDone ?? this.beforeSunnahDone,
      sunnahDone: sunnahDone ?? this.sunnahDone,
      witrDone: witrDone ?? this.witrDone,
    );
  }

  /// Marks every applicable segment on or off at once.
  PrayerItem markAll(bool value) {
    return copyWith(
      inMasjid: value,
      fardDone: value,
      beforeSunnahDone: beforeSunnah > 0 ? value : false,
      sunnahDone: sunnah > 0 ? value : false,
      witrDone: witr > 0 ? value : false,
    );
  }

  factory PrayerItem.fromMap(Map<String, dynamic> m) {
    return PrayerItem(
      name: m['name'] as String,
      fard: (m['fard'] as num).toInt(),
      beforeSunnah: (m['beforeSunnah'] as num?)?.toInt() ?? 0,
      sunnah: (m['sunnah'] as num?)?.toInt() ?? 0,
      witr: (m['witr'] as num?)?.toInt() ?? 0,
      inMasjid: (m['inMasjid'] as bool?) ?? false,
      fardDone: (m['fardDone'] as bool?) ?? false,
      beforeSunnahDone: (m['beforeSunnahDone'] as bool?) ?? false,
      sunnahDone: (m['sunnahDone'] as bool?) ?? false,
      witrDone: (m['witrDone'] as bool?) ?? false,
    );
  }

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

/// Daily collection of the five prayers and their summary metrics.
class DailyPrayerLog {
  final String dateKey;
  final List<PrayerItem> prayers;

  const DailyPrayerLog({
    required this.dateKey,
    required this.prayers,
  });

  static List<PrayerItem> defaultPrayers() => const [
        PrayerItem(name: 'Fajr', fard: 2, beforeSunnah: 0, sunnah: 2),
        PrayerItem(name: 'Dhuhr', fard: 4, beforeSunnah: 4, sunnah: 4),
        PrayerItem(name: 'Asr', fard: 4, beforeSunnah: 0, sunnah: 4),
        PrayerItem(name: 'Maghrib', fard: 3, beforeSunnah: 0, sunnah: 2),
        PrayerItem(name: 'Isha', fard: 4, beforeSunnah: 0, sunnah: 2, witr: 3),
      ];

  int get totalPrayers => prayers.length;
  int get completedPrayers => prayers.where((p) => p.status == AwradStatus.done).length;
  int get halfDonePrayers => prayers.where((p) => p.status == AwradStatus.halfDone).length;
  int get fardCompletedCount => prayers.where((p) => p.fardDone).length;
  int get inMasjidCount => prayers.where((p) => p.inMasjid).length;
  int get totalRakahs => prayers.fold(0, (sum, p) => sum + p.totalRakahs);
  int get completedRakahs => prayers.fold(0, (sum, p) => sum + p.completedRakahs);

  double get completionScore {
    if (prayers.isEmpty) return 0.0;
    final total = prayers.fold<double>(0.0, (sum, p) => sum + p.status.score);
    return total / prayers.length;
  }
}
