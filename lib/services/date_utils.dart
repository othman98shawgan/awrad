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

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] into a friendly label such as `Today · Tue, Nov 24`
/// or `Mon, Nov 16` (including year when different from [now]).
String formatFriendlyDate(DateTime date, {DateTime? now}) {
  final target = normalizeDate(date);
  final today = normalizeDate(now ?? DateTime.now());
  final diff = target.difference(today).inDays;

  final dayPart =
      '${_weekdayShort[target.weekday - 1]}, ${_monthShort[target.month - 1]} ${target.day}';
  final withYear = target.year == today.year ? dayPart : '$dayPart, ${target.year}';

  if (diff == 0) return 'Today · $dayPart';
  if (diff == -1) return 'Yesterday · $dayPart';
  if (diff == 1) return 'Tomorrow · $dayPart';
  return withYear;
}

const hijriMonthNames = [
  'Muharram',
  'Safar',
  "Rabi' al-Awwal",
  "Rabi' al-Thani",
  'Jumada al-Ula',
  'Jumada al-Akhirah',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah',
];

/// Represents a date in the Islamic (Hijri) calendar.
class HijriDate {
  final int year;
  final int month;
  final int day;

  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
  });

  String get monthName => hijriMonthNames[month - 1];

  String format() => '$day $monthName $year AH';

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Converts a Gregorian [DateTime] to a civil/tabular [HijriDate].
HijriDate toHijriDate(DateTime date) {
  final d = normalizeDate(date);
  final a = (14 - d.month) ~/ 12;
  final y = d.year + 4800 - a;
  final m = d.month + 12 * a - 3;
  final jd = d.day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;

  var l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final hMonth = (24 * l) ~/ 709;
  final hDay = l - (709 * hMonth) ~/ 24;
  final hYear = 30 * n + j - 30;

  return HijriDate(year: hYear, month: hMonth, day: hDay);
}

/// Formats [date] as a readable Hijri date string (e.g. `15 Jumada al-Akhirah 1448 AH`).
String formatHijriDate(DateTime date) => toHijriDate(date).format();

/// Formats a Hijri date range spanning [start] to [end].
String formatHijriRange(
  DateTime start,
  DateTime end, {
  bool includeDays = false,
}) {
  final s = toHijriDate(start);
  final e = toHijriDate(end);

  if (s.year == e.year && s.month == e.month) {
    return includeDays
        ? '${s.day} – ${e.day} ${s.monthName} ${s.year} AH'
        : '${s.monthName} ${s.year} AH';
  }
  if (s.year == e.year) {
    return includeDays
        ? '${s.day} ${s.monthName} – ${e.day} ${e.monthName} ${s.year} AH'
        : '${s.monthName} – ${e.monthName} ${s.year} AH';
  }
  return includeDays
      ? '${s.format()} – ${e.format()}'
      : '${s.monthName} ${s.year} – ${e.monthName} ${e.year} AH';
}

/// Converts a civil/tabular [HijriDate] (year, month, day) to Gregorian [DateTime].
DateTime hijriToGregorian(int hYear, int hMonth, int hDay) {
  final jd = ((11 * hYear + 3) ~/ 30) +
      354 * hYear +
      30 * hMonth -
      ((hMonth - 1) ~/ 2) +
      hDay +
      1948440 -
      385;
  var l = jd + 68569;
  final n = (4 * l) ~/ 146097;
  l = l - (146097 * n + 3) ~/ 4;
  final i = (4000 * (l + 1)) ~/ 1461001;
  l = l - (1461 * i) ~/ 4 + 31;
  final j = (80 * l) ~/ 2447;
  final day = l - (2447 * j) ~/ 80;
  l = j ~/ 11;
  final month = j + 2 - 12 * l;
  final year = 100 * (n - 49) + i + l;
  return DateTime(year, month, day);
}

/// Returns the Gregorian `(start, end)` bounds of the Hijri month containing [anchor].
(DateTime, DateTime) hijriMonthRange(DateTime anchor) {
  final h = toHijriDate(anchor);
  final start = hijriToGregorian(h.year, h.month, 1);
  final nextYear = h.month == 12 ? h.year + 1 : h.year;
  final nextMonth = h.month == 12 ? 1 : h.month + 1;
  final nextStart = hijriToGregorian(nextYear, nextMonth, 1);
  final end = DateTime(nextStart.year, nextStart.month, nextStart.day - 1);
  return (start, end);
}

/// Steps [anchor] by [delta] Hijri months and returns the 1st of that Hijri month.
DateTime stepHijriMonth(DateTime anchor, int delta) {
  final h = toHijriDate(anchor);
  final totalMonths = (h.year * 12) + (h.month - 1) + delta;
  final targetYear = totalMonths ~/ 12;
  final targetMonth = (totalMonths % 12) + 1;
  return hijriToGregorian(targetYear, targetMonth, 1);
}
