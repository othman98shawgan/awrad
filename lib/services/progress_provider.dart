import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/awrad_status.dart';
import '../models/awrad_task.dart';
import '../models/prayer_item.dart';
import 'awrad_provider.dart';
import 'date_utils.dart';
import 'prayer_provider.dart';

/// Anchor date for the Progress tab's Weekly/Monthly view.
final progressAnchorDateProvider = StateProvider<DateTime>(
  (ref) => normalizeDate(DateTime.now()),
);

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

/// Per-task completion breakdown over a selected date range.
class AwradTaskSummary {
  final String taskId;
  final String title;
  final int applicableDays;
  final int doneDays;
  final int halfDays;

  const AwradTaskSummary({
    required this.taskId,
    required this.title,
    required this.applicableDays,
    required this.doneDays,
    required this.halfDays,
  });

  double get completionRate {
    if (applicableDays == 0) return 0.0;
    return (doneDays + (halfDays * 0.5)) / applicableDays;
  }
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

/// Computes per-task completion breakdown across [ProgressRangeQuery].
final awradTaskBreakdownProvider = FutureProvider.autoDispose
    .family<List<AwradTaskSummary>, ProgressRangeQuery>((ref, query) async {
  ref.watch(awradDataVersionProvider);
  final awradRepo = ref.watch(awradRepositoryProvider);
  final tasks = ref.watch(awradTasksProvider);

  final effectiveTasks = tasks.isNotEmpty ? tasks : await awradRepo.loadTasks();
  final awradLogs = await awradRepo.loadLogsInRange(query.start, query.end);
  final days = datesInRange(query.start, query.end);

  return effectiveTasks
      .where((t) => !t.isArchived)
      .map((task) {
        int applicable = 0;
        int done = 0;
        int half = 0;
        for (final date in days) {
          if (!task.appliesTo(date)) continue;
          applicable++;
          final key = formatDateKey(date);
          final status = awradLogs[key]?.statusFor(task.id) ?? AwradStatus.notDone;
          if (status == AwradStatus.done) done++;
          if (status == AwradStatus.halfDone) half++;
        }
        return AwradTaskSummary(
          taskId: task.id,
          title: task.title,
          applicableDays: applicable,
          doneDays: done,
          halfDays: half,
        );
      })
      .where((s) => s.applicableDays > 0)
      .toList();
});
