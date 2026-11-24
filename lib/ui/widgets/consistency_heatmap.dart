import 'package:flutter/material.dart';

import '../../services/date_utils.dart';
import '../../services/progress_provider.dart';
import '../theme/app_theme.dart';

/// GitHub-style consistency heatmap supporting both Weekly (7-day row) and
/// Monthly (Mon–Sun multi-week contribution grid) views.
class ConsistencyHeatmap extends StatelessWidget {
  final List<DailyProgressSummary> days;
  final bool isMonthly;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTime> onViewDay;

  const ConsistencyHeatmap({
    super.key,
    required this.days,
    required this.isMonthly,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onViewDay,
  });

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final byDate = {for (final d in days) d.date: d};
    final activeDay = selectedDate != null ? byDate[selectedDate!] : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consistency Heatmap',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap any day to inspect or jump to its Awrad',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.mutedText,
              ),
            ),
            const SizedBox(height: 14),
            if (isMonthly)
              _buildMonthlyGrid(context, colors, theme)
            else
              _buildWeeklyRow(context, colors, theme),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Less',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
                const SizedBox(width: 6),
                for (final levelColor in colors.heatmapLevels) ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  'More',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
            if (activeDay != null) ...[
              const SizedBox(height: 12),
              _SelectedDayStrip(
                summary: activeDay,
                onViewDay: () => onViewDay(activeDay.date),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyRow(
    BuildContext context,
    AwradColors colors,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final isSelected = selectedDate == day.date;
        final cellColor = _colorForScore(day.awradScore, colors);
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelectDate(day.date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              children: [
                Text(
                  _dayLabels[day.date.weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? colors.emerald : colors.mutedText,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: colors.emerald, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: day.awradScore >= 0.4
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyGrid(
    BuildContext context,
    AwradColors colors,
    ThemeData theme,
  ) {
    if (days.isEmpty) return const SizedBox.shrink();

    // Pad leading slots before the 1st of the month so rows align Mon(0)..Sun(6).
    final leadingBlanks = days.first.date.weekday - 1;
    final cells = <DailyProgressSummary?>[
      ...List<DailyProgressSummary?>.filled(leadingBlanks, null),
      ...days,
    ];
    final weekCount = (cells.length / 7).ceil();
    while (cells.length < weekCount * 7) {
      cells.add(null);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (weekdayIdx) {
            final showLabel = weekdayIdx == 0 || weekdayIdx == 2 || weekdayIdx == 4;
            return SizedBox(
              height: 28,
              width: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: showLabel
                    ? Text(
                        _dayLabels[weekdayIdx],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      )
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(weekCount, (weekIdx) {
              return Expanded(
                child: Column(
                  children: List.generate(7, (weekdayIdx) {
                    final item = cells[weekIdx * 7 + weekdayIdx];
                    if (item == null) {
                      return const SizedBox(height: 28);
                    }
                    final isSelected = selectedDate == item.date;
                    final cellColor = _colorForScore(item.awradScore, colors);
                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => onSelectDate(item.date),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          height: 24,
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? Border.all(color: colors.emerald, width: 2)
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Color _colorForScore(double score, AwradColors colors) {
    if (score <= 0) return colors.heatmapLevels[0];
    if (score < 0.4) return colors.heatmapLevels[1];
    if (score < 0.75) return colors.heatmapLevels[2];
    return colors.heatmapLevels[3];
  }
}

class _SelectedDayStrip extends StatelessWidget {
  final DailyProgressSummary summary;
  final VoidCallback onViewDay;

  const _SelectedDayStrip({
    required this.summary,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final awradText = summary.awradHalfDone > 0
        ? '${summary.awradDone}/${summary.awradTotal} Awrad (${summary.awradHalfDone} half)'
        : '${summary.awradDone}/${summary.awradTotal} Awrad';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.emeraldSoft.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatFriendlyDate(summary.date),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$awradText · ${summary.prayersDone}/5 Prayers (${summary.prayersInMasjid} Masjid)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onViewDay,
            child: Text(
              'View Day →',
              style: TextStyle(
                color: colors.emerald,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
