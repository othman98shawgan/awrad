import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/awrad_status.dart';
import '../models/awrad_task.dart';
import '../models/prayer_item.dart';
import 'awrad_provider.dart';
import 'date_utils.dart';
import 'prayer_provider.dart';

/// Computes the current consecutive-day streak ending at [today] (or yesterday
/// if [today] has no progress yet) where `awradScore > 0`.
int computeAwradStreak(
  List<DailyProgressSummary> summaries, {
  DateTime? now,
}) {
  if (summaries.isEmpty) return 0;
  final today = normalizeDate(now ?? DateTime.now());
  final byDate = {for (final s in summaries) s.date: s};

  var cursor = today;
  if ((byDate[cursor]?.awradScore ?? 0) <= 0) {
    cursor = DateTime(today.year, today.month, today.day - 1);
  }

  var streak = 0;
  while (true) {
    final summary = byDate[cursor];
    if (summary == null || summary.awradScore <= 0) break;
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return streak;
}

/// Aggregated Awrad + Prayer metrics for a single calendar day.
class DailyProgressSummary {
  final DateTime date;
  final int awradTotal;
  final int awradDone;
  final int awradHalfDone;
  final double awradScore;
  final int prayersDone;
  final int prayersHalfDone;
  final int prayersInMasjid;
  final int completedRakahs;
  final int totalRakahs;

  const DailyProgressSummary({
    required this.date,
    required this.awradTotal,
    required this.awradDone,
    required this.awradHalfDone,
    required this.awradScore,
    required this.prayersDone,
    required this.prayersHalfDone,
    required this.prayersInMasjid,
    required this.completedRakahs,
    required this.totalRakahs,
  });

  bool get hasPartialAwrad => awradHalfDone > 0;
}

/// Parameter object for querying progress over an inclusive date range.
class ProgressRangeQuery {
  final DateTime start;
  final DateTime end;

  ProgressRangeQuery(DateTime start, DateTime end)
      : start = normalizeDate(start),
        end = normalizeDate(end);

  @override
  bool operator ==(Object other) =>
      other is ProgressRangeQuery && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Computes daily progress summaries across a date range for heatmaps & reports.
final progressRangeProvider = FutureProvider.autoDispose
    .family<List<DailyProgressSummary>, ProgressRangeQuery>((ref, query) async {
  ref.watch(awradDataVersionProvider);
  ref.watch(prayerDataVersionProvider);
  final awradRepo = ref.watch(awradRepositoryProvider);
  final prayerRepo = ref.watch(prayerRepositoryProvider);
  final tasks = ref.watch(awradTasksProvider);

  final effectiveTasks = tasks.isNotEmpty ? tasks : await awradRepo.loadTasks();
  final awradLogs = await awradRepo.loadLogsInRange(query.start, query.end);
  final prayerLogs = await prayerRepo.loadLogsInRange(query.start, query.end);

  final summaries = <DailyProgressSummary>[];
  for (final date in datesInRange(query.start, query.end)) {
    final key = formatDateKey(date);
    final applicableTasks =
        effectiveTasks.where((AwradTask t) => t.appliesTo(date)).toList();
    final awradLog = awradLogs[key];

    int done = 0;
    int half = 0;
    double scoreSum = 0.0;
    for (final task in applicableTasks) {
      final status = awradLog?.statusFor(task.id) ?? AwradStatus.notDone;
      if (status == AwradStatus.done) done++;
      if (status == AwradStatus.halfDone) half++;
      scoreSum += status.score;
    }

    final awradScore =
        applicableTasks.isEmpty ? 0.0 : scoreSum / applicableTasks.length;

    final prayerLog = prayerLogs[key] ??
        DailyPrayerLog(dateKey: key, prayers: DailyPrayerLog.defaultPrayers());

    summaries.add(
      DailyProgressSummary(
        date: date,
        awradTotal: applicableTasks.length,
        awradDone: done,
        awradHalfDone: half,
        awradScore: awradScore,
        prayersDone: prayerLog.completedPrayers,
        prayersHalfDone: prayerLog.halfDonePrayers,
        prayersInMasjid: prayerLog.inMasjidCount,
        completedRakahs: prayerLog.completedRakahs,
        totalRakahs: prayerLog.totalRakahs,
      ),
    );
  }
  return summaries;
});
