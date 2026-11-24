import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'date_utils.dart';

/// A single normalized source-of-truth for the currently selected calendar date.
final selectedDateProvider =
    StateNotifierProvider<SelectedDateNotifier, DateTime>((ref) {
  return SelectedDateNotifier();
});

class SelectedDateNotifier extends StateNotifier<DateTime> {
  SelectedDateNotifier([DateTime? initialDate])
      : super(normalizeDate(initialDate ?? DateTime.now()));

  void selectDate(DateTime date) {
    final normalized = normalizeDate(date);
    if (normalized != state) {
      state = normalized;
    }
  }

  void stepDays(int delta) {
    state = DateTime(state.year, state.month, state.day + delta);
  }

  void goToToday() {
    selectDate(DateTime.now());
  }
}
