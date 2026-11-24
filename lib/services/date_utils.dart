/// Strips time-of-day components so calendar dates can safely be used
/// as map keys and Riverpod `.family` arguments.
DateTime normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// Formats [date] as an ISO calendar date string (`YYYY-MM-DD`).
String formatDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Parses a `YYYY-MM-DD` key back into a normalized local [DateTime].
DateTime? parseDateKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Returns every normalized date from [start] to [end] inclusive.
List<DateTime> datesInRange(DateTime start, DateTime end) {
  final s = normalizeDate(start);
  final e = normalizeDate(end);
  if (e.isBefore(s)) return const [];
  final days = e.difference(s).inDays + 1;
  return List.generate(days, (i) => DateTime(s.year, s.month, s.day + i));
}
