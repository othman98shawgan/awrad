import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'prayer_service.dart';
import 'selected_date_provider.dart';

final prayerListProvider = StateNotifierProvider.autoDispose.family<PrayerListNotifier, List<PrayerItem>, DateTime>(
  (ref, date) => PrayerListNotifier(date),
);

class PrayerListNotifier extends StateNotifier<List<PrayerItem>> {
  final DateTime date;

  PrayerListNotifier(this.date) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final stored = await PrayerService.load(date);
    if (stored.isNotEmpty) {
      state = stored;
    } else {
      // default prayers, with beforeSunnah only for Dhuhr
      state = [
        PrayerItem(name: 'Fajr', fard: 2, beforeSunnah: 0, sunnah: 2),
        PrayerItem(name: 'Dhuhr', fard: 4, beforeSunnah: 4, sunnah: 4),
        PrayerItem(name: 'Asr', fard: 4, beforeSunnah: 0, sunnah: 4),
        PrayerItem(name: 'Maghrib', fard: 3, beforeSunnah: 0, sunnah: 2),
        PrayerItem(name: 'Isha', fard: 4, beforeSunnah: 0, sunnah: 2, witr: 3),
      ];
    }
    PrayerService.save(date, state);
  }

  void toggleMain(int i, bool? v) {
    final p = state[i];
    final mark = v == true;
    p.inMasjid = mark;
    p.fardDone = mark;
    p.beforeSunnahDone = mark;
    p.sunnahDone = mark;
    if (p.witr > 0) p.witrDone = mark;
    p.done = v;
    _apply();
  }

  void toggleInMasjid(int i, bool v) {
    state[i].inMasjid = v;
    _recalcDone(state[i]);
    _apply();
  }

  void toggleFard(int i, bool v) {
    state[i].fardDone = v;
    _recalcDone(state[i]);
    _apply();
  }

  void toggleBeforeSunnah(int i, bool v) {
    state[i].beforeSunnahDone = v;
    _recalcDone(state[i]);
    _apply();
  }

  void toggleSunnah(int i, bool v) {
    state[i].sunnahDone = v;
    _recalcDone(state[i]);
    _apply();
  }

  void toggleWitr(int i, bool v) {
    state[i].witrDone = v;
    _recalcDone(state[i]);
    _apply();
  }

  void _recalcDone(PrayerItem p) {
    final all = p.inMasjid &&
        p.fardDone &&
        (p.beforeSunnah > 0 ? p.beforeSunnahDone : true) &&
        p.sunnahDone &&
        (p.witr > 0 ? p.witrDone : true);
    final any = p.inMasjid ||
        p.fardDone ||
        (p.beforeSunnah > 0 ? p.beforeSunnahDone : false) ||
        p.sunnahDone ||
        (p.witr > 0 ? p.witrDone : false);
    p.done = all ? true : (any ? null : false);
  }

  Future<void> _apply() async {
    state = [...state];
    PrayerService.save(date, state);
  }
}
