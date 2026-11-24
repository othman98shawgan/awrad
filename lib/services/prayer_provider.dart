import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/prayer_item.dart';
import 'date_utils.dart';
import 'prayer_repository.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return LocalPrayerRepository();
});

/// Loads and mutates the five daily prayers for a normalized [DateTime].
final prayerListProvider = StateNotifierProvider.autoDispose
    .family<PrayerListNotifier, List<PrayerItem>, DateTime>((ref, date) {
  final repo = ref.watch(prayerRepositoryProvider);
  return PrayerListNotifier(repo, normalizeDate(date));
});

class PrayerListNotifier extends StateNotifier<List<PrayerItem>> {
  final PrayerRepository _repo;
  final DateTime date;

  PrayerListNotifier(this._repo, this.date)
      : super(DailyPrayerLog.defaultPrayers()) {
    _load();
  }

  Future<void> _load() async {
    final log = await _repo.loadLog(date);
    if (!mounted) return;
    state = log.prayers;
  }

  Future<void> toggleMain(int index, bool? value) async {
    if (index < 0 || index >= state.length) return;
    final mark = value == true;
    await _updateAt(index, (p) => p.markAll(mark));
  }

  Future<void> toggleInMasjid(int index, bool value) async {
    await _updateAt(index, (p) => p.copyWith(inMasjid: value));
  }

  Future<void> toggleFard(int index, bool value) async {
    await _updateAt(index, (p) => p.copyWith(fardDone: value));
  }

  Future<void> toggleBeforeSunnah(int index, bool value) async {
    await _updateAt(index, (p) => p.copyWith(beforeSunnahDone: value));
  }

  Future<void> toggleSunnah(int index, bool value) async {
    await _updateAt(index, (p) => p.copyWith(sunnahDone: value));
  }

  Future<void> toggleWitr(int index, bool value) async {
    await _updateAt(index, (p) => p.copyWith(witrDone: value));
  }

  Future<void> _updateAt(
    int index,
    PrayerItem Function(PrayerItem current) transform,
  ) async {
    if (index < 0 || index >= state.length) return;
    final updated = [
      for (int i = 0; i < state.length; i++)
        if (i == index) transform(state[i]) else state[i],
    ];
    state = updated;
    await _repo.saveLog(
      DailyPrayerLog(dateKey: formatDateKey(date), prayers: updated),
    );
  }
}
