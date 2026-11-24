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

  (DateTime, DateTime) _currentRange(DateTime anchorDate) {
    if (_period == _ProgressPeriod.monthly) {
      final start = DateTime(anchorDate.year, anchorDate.month, 1);
      final end = DateTime(anchorDate.year, anchorDate.month + 1, 0);
      return (start, end);
    }
    // Weekly: Monday..Sunday containing anchorDate
    final start = DateTime(
      anchorDate.year,
      anchorDate.month,
      anchorDate.day - (anchorDate.weekday - 1),
    );
    final end = DateTime(start.year, start.month, start.day + 6);
    return (start, end);
  }

  String _periodLabel(DateTime start, DateTime end) {
    if (_period == _ProgressPeriod.monthly) {
      return '${_monthNames[start.month - 1]} ${start.year}';
    }
    final startText = '${_monthShort[start.month - 1]} ${start.day}';
    final endText = '${_monthShort[end.month - 1]} ${end.day}';
    return '$startText – $endText';
  }

  void _stepPeriod(DateTime anchorDate, int delta) {
    final next = _period == _ProgressPeriod.monthly
        ? DateTime(anchorDate.year, anchorDate.month + delta, 1)
        : DateTime(
            anchorDate.year,
            anchorDate.month,
            anchorDate.day + (delta * 7),
          );
    ref.read(progressAnchorDateProvider.notifier).state = next;
    setState(() {
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final anchorDate = ref.watch(progressAnchorDateProvider);
    final (start, end) = _currentRange(anchorDate);
    final label = _periodLabel(start, end);

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
    final taskBreakdownAsync =
        ref.watch(awradTaskBreakdownProvider(rangeQuery));
    final taskSummaries =
        taskBreakdownAsync.valueOrNull ?? const <AwradTaskSummary>[];

    final streakEnd = normalizeDate(DateTime.now());
    final streakStart =
        DateTime(streakEnd.year, streakEnd.month, streakEnd.day - 60);
    final streakAsync = ref.watch(
      progressRangeProvider(ProgressRangeQuery(streakStart, streakEnd)),
    );
    final streak = computeAwradStreak(streakAsync.valueOrNull ?? days);

    final awradPct = days.isEmpty
        ? 0
        : ((days.fold<double>(0.0, (s, d) => s + d.awradScore) / days.length) *
                100)
            .round();
    final totalFardPossible = days.length * 5;
    final totalMasjid = days.fold<int>(0, (s, d) => s + d.prayersInMasjid);
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
                onPressed: () => _stepPeriod(anchorDate, -1),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next period',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _stepPeriod(anchorDate, 1),
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
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress Report',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share your $label summary',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: days.isEmpty
                      ? null
                      : () => showProgressReportSheet(
                            context,
                            periodLabel: label,
                            days: days,
                            taskSummaries: taskSummaries,
                            streakDays: streak,
                          ),
                  icon: const Icon(Icons.ios_share_rounded, size: 17),
                  label: const Text('Report'),
                ),
              ],
            ),
          ),
        ),
      ],
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
