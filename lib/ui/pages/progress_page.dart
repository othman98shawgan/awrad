import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/date_utils.dart';
import '../../services/progress_provider.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/consistency_heatmap.dart';
import '../widgets/teacher_report_sheet.dart';

enum _ProgressPeriod { weekly, monthly }

class ProgressPage extends ConsumerStatefulWidget {
  final VoidCallback? onJumpToAwrad;

  const ProgressPage({super.key, this.onJumpToAwrad});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  _ProgressPeriod _period = _ProgressPeriod.monthly;
  DateTime? _selectedDay;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _monthShort = [
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

  @override
  void initState() {
    super.initState();
    _selectedDay = normalizeDate(DateTime.now());
  }

  (DateTime, DateTime) _currentRange(DateTime anchorDate, bool isHijri) {
    if (_period == _ProgressPeriod.monthly) {
      if (isHijri) {
        return hijriMonthRange(anchorDate);
      }
      final start = DateTime(anchorDate.year, anchorDate.month, 1);
      final end = DateTime(anchorDate.year, anchorDate.month + 1, 0);
      return (start, end);
    }
    // Weekly: Sunday..Saturday containing anchorDate
    final daysSinceSunday = anchorDate.weekday % 7;
    final start = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day - daysSinceSunday,
    );
    final end = DateTime(start.year, start.month, start.day + 6);
    return (start, end);
  }

  String _periodLabel(DateTime start, DateTime end, bool isHijri) {
    if (_period == _ProgressPeriod.monthly) {
      if (isHijri) {
        final h = toHijriDate(start);
        return '${h.monthName} ${h.year} AH';
      }
      return '${_monthNames[start.month - 1]} ${start.year}';
    }
    final startText = '${_monthShort[start.month - 1]} ${start.day}';
    final endText = '${_monthShort[end.month - 1]} ${end.day}';
    return '$startText – $endText';
  }

  String _periodSubtitle(DateTime start, DateTime end, bool isHijri) {
    if (_period == _ProgressPeriod.monthly && isHijri) {
      final startText = '${_monthShort[start.month - 1]} ${start.day}';
      final endText = '${_monthShort[end.month - 1]} ${end.day}';
      if (start.year == end.year) {
        return '$startText – $endText, ${start.year}';
      }
      return '$startText, ${start.year} – $endText, ${end.year}';
    }
    return formatHijriRange(
      start,
      end,
      includeDays: _period == _ProgressPeriod.weekly,
    );
  }

  void _stepPeriod(DateTime anchorDate, int delta, bool isHijri) {
    final DateTime next;
    if (_period == _ProgressPeriod.monthly) {
      next = isHijri
          ? stepHijriMonth(anchorDate, delta)
          : DateTime(anchorDate.year, anchorDate.month + delta, 1);
    } else {
      next = DateTime(
        anchorDate.year,
        anchorDate.month,
        anchorDate.day + (delta * 7),
      );
    }
    ref.read(progressAnchorDateProvider.notifier).state = next;
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final today = normalizeDate(DateTime.now());
    final anchorDate = ref.watch(progressAnchorDateProvider);
    final isHijri = ref.watch(progressHijriCalendarProvider);
    final (start, end) = _currentRange(anchorDate, isHijri);
    final label = _periodLabel(start, end, isHijri);

    final rangeQuery = ProgressRangeQuery(start, end);
    final rangeAsync = ref.watch(progressRangeProvider(rangeQuery));
    final days = rangeAsync.valueOrNull ??
        datesInRange(start, end)
            .map(
              (d) => DailyProgressSummary(
                date: d,
                awradTotal: 0,
                awradDone: 0,
                awradHalfDone: 0,
                awradScore: 0,
                prayersDone: 0,
                prayersHalfDone: 0,
                prayersInMasjid: 0,
                completedRakahs: 0,
                totalRakahs: 0,
              ),
            )
            .toList();

    // Reports and period percentages only count elapsed days (past days + today).
    final elapsedDays = days.where((d) => !d.date.isAfter(today)).toList();
    final elapsedEnd = end.isAfter(today) ? today : end;
    final elapsedQuery = elapsedEnd.isBefore(start)
        ? ProgressRangeQuery(DateTime(2000, 1, 2), DateTime(2000, 1, 1))
        : ProgressRangeQuery(start, elapsedEnd);

    final taskBreakdownAsync =
        ref.watch(awradTaskBreakdownProvider(elapsedQuery));
    final taskSummaries =
        taskBreakdownAsync.valueOrNull ?? const <AwradTaskSummary>[];
    final prayerBreakdownAsync =
        ref.watch(prayerBreakdownProvider(elapsedQuery));
    final prayerSummaries =
        prayerBreakdownAsync.valueOrNull ?? const <PrayerPeriodSummary>[];

    final streakStart = DateTime(today.year, today.month, today.day - 60);
    final streakAsync = ref.watch(
      progressRangeProvider(ProgressRangeQuery(streakStart, today)),
    );
    final streakSummaries = streakAsync.valueOrNull ?? elapsedDays;
    final streak = computeAwradStreak(streakSummaries);
    final bestStreak = computeBestAwradStreak(streakSummaries);
    final prayerStreak = computePrayerStreak(streakSummaries);

    final awradPct = elapsedDays.isEmpty
        ? 0
        : ((elapsedDays.fold<double>(0.0, (s, d) => s + d.awradScore) /
                    elapsedDays.length) *
                100)
            .round();
    final totalFardPossible = elapsedDays.length * 5;
    final totalMasjid =
        elapsedDays.fold<int>(0, (s, d) => s + d.prayersInMasjid);
    final masjidPct = totalFardPossible == 0
        ? 0
        : ((totalMasjid / totalFardPossible) * 100).round();

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_ProgressPeriod>(
            segments: const [
              ButtonSegment(
                value: _ProgressPeriod.weekly,
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: _ProgressPeriod.monthly,
                label: Text('Monthly'),
              ),
            ],
            selected: {_period},
            onSelectionChanged: (sel) {
              setState(() {
                _period = sel.first;
                _selectedDay = null;
              });
              ref.read(progressIsMonthlyProvider.notifier).state =
                  sel.first == _ProgressPeriod.monthly;
            },
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous period',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _stepPeriod(anchorDate, -1, isHijri),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _periodSubtitle(start, end, isHijri),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next period',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _stepPeriod(anchorDate, 1, isHijri),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ConsistencyHeatmap(
          days: days,
          isMonthly: _period == _ProgressPeriod.monthly,
          selectedDate: _selectedDay,
          onSelectDate: (d) => setState(() => _selectedDay = d),
          onViewDay: (d) {
            ref.read(selectedDateProvider.notifier).selectDate(d);
            widget.onJumpToAwrad?.call();
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ProgressStatCard(
                label: 'Streak',
                value: '${streak}d',
                icon: Icons.local_fire_department_rounded,
                iconColor: colors.amber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProgressStatCard(
                label: 'Awrad',
                value: '$awradPct%',
                icon: Icons.trending_up_rounded,
                iconColor: colors.emerald,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProgressStatCard(
                label: 'In Masjid',
                value: '$masjidPct%',
                icon: Icons.mosque_outlined,
                iconColor: colors.emerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StreakMilestonesCard(
          currentStreak: streak,
          bestStreak: bestStreak,
          prayerStreak: prayerStreak,
        ),
        const SizedBox(height: 14),
        _ReportActionCard(
          title: 'Awrad Report',
          subtitle: 'Elapsed days in $label (${elapsedDays.length}d)',
          icon: Icons.checklist_rounded,
          onPressed: elapsedDays.isEmpty
              ? null
              : () => showAwradReportSheet(
                    context,
                    periodLabel: label,
                    elapsedDays: elapsedDays,
                    taskSummaries: taskSummaries,
                    streakDays: streak,
                  ),
        ),
        const SizedBox(height: 10),
        _ReportActionCard(
          title: 'Prayers Report',
          subtitle: 'Elapsed days in $label (${elapsedDays.length}d)',
          icon: Icons.mosque_outlined,
          onPressed: elapsedDays.isEmpty
              ? null
              : () => showPrayersReportSheet(
                    context,
                    periodLabel: label,
                    elapsedDays: elapsedDays,
                    prayerSummaries: prayerSummaries,
                  ),
        ),
      ],
    );
  }
}

class _ReportActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ReportActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 17),
              label: const Text('Report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _ProgressStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakMilestonesCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final int prayerStreak;

  const _StreakMilestonesCard({
    required this.currentStreak,
    required this.bestStreak,
    required this.prayerStreak,
  });

  static const _milestones = [3, 7, 14, 30, 40];

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final effectiveBest = bestStreak > currentStreak ? bestStreak : currentStreak;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: colors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  'Streaks & Milestones',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Best: ${effectiveBest}d · 5/5 Fard: ${prayerStreak}d',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: _milestones.map((days) {
                final unlocked = effectiveBest >= days;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: days == _milestones.last ? 0 : 6,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? colors.emeraldSoft
                            : colors.heatmapLevels[0].withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: unlocked
                              ? colors.emerald.withValues(alpha: 0.5)
                              : colors.cardBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            unlocked
                                ? Icons.verified_rounded
                                : Icons.lock_outline_rounded,
                            size: 13,
                            color: unlocked ? colors.emerald : colors.mutedText,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${days}d',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  unlocked ? colors.emerald : colors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
