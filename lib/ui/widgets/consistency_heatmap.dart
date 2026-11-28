import 'package:flutter/material.dart';

import '../../models/awrad_status.dart';
import '../../models/awrad_task.dart';
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

  static const _sundayFirstLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

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
                  _sundayFirstLabels[day.date.weekday % 7],
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

    // Pad leading slots before the 1st of the month so rows align Sun(0)..Sat(6).
    final leadingBlanks = days.first.date.weekday % 7;
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
                        _sundayFirstLabels[weekdayIdx],
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
                const SizedBox(height: 1),
                Text(
                  formatHijriDate(summary.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
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

/// Consistency heatmap scoped to a single [AwradTask], showing Done, Half
/// (light green), Missed, and Off-day states along with daily task notes.
class WirdConsistencyHeatmap extends StatelessWidget {
  final AwradTask task;
  final List<WirdDayProgress> days;
  final bool isMonthly;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<DateTime> onViewDay;

  const WirdConsistencyHeatmap({
    super.key,
    required this.task,
    required this.days,
    required this.isMonthly,
    required this.selectedDate,
    required this.onSelectDate,
    required this.onViewDay,
  });

  static const _sundayFirstLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const _isoWeekdayShort = {
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  String _scheduleLabel() {
    if (task.repeatWeekdays.isEmpty) return 'Daily';
    final ordered = task.repeatWeekdays.toList()..sort();
    return ordered.map((d) => _isoWeekdayShort[d] ?? '').join(', ');
  }

  Color _halfColor(AwradColors colors, ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? colors.heatmapLevels[2]
        : colors.heatmapLevels[1];
  }

  Color _offDayColor(AwradColors colors) =>
      colors.heatmapLevels[0].withValues(alpha: 0.25);

  Color _colorForDay(
    WirdDayProgress day,
    AwradColors colors,
    ThemeData theme,
  ) {
    if (!day.isApplicable) return _offDayColor(colors);
    switch (day.status) {
      case AwradStatus.notDone:
        return colors.heatmapLevels[0];
      case AwradStatus.halfDone:
        return _halfColor(colors, theme);
      case AwradStatus.done:
        return colors.heatmapLevels[3];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final byDate = {for (final d in days) d.date: d};
    final activeDay = selectedDate != null ? byDate[selectedDate!] : null;
    final hasOffDays = task.repeatWeekdays.isNotEmpty;

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
              '${_scheduleLabel()} · Tap any day to inspect',
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
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 6,
              children: [
                if (hasOffDays)
                  _LegendItem(
                    color: _offDayColor(colors),
                    borderColor: colors.cardBorder,
                    label: 'Off',
                  ),
                _LegendItem(
                  color: colors.heatmapLevels[0],
                  label: 'Missed',
                ),
                _LegendItem(
                  color: _halfColor(colors, theme),
                  label: 'Half',
                ),
                _LegendItem(
                  color: colors.heatmapLevels[3],
                  label: 'Done',
                ),
              ],
            ),
            if (activeDay != null) ...[
              const SizedBox(height: 12),
              _WirdSelectedDayStrip(
                day: activeDay,
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
        final cellColor = _colorForDay(day, colors, theme);
        final textColor = !day.isApplicable
            ? colors.mutedText.withValues(alpha: 0.65)
            : day.status == AwradStatus.done ||
                    (day.status == AwradStatus.halfDone &&
                        theme.brightness == Brightness.dark)
                ? Colors.white
                : theme.colorScheme.onSurface;

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelectDate(day.date),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              children: [
                Text(
                  _sundayFirstLabels[day.date.weekday % 7],
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
                        : (!day.isApplicable
                            ? Border.all(
                                color: colors.cardBorder.withValues(alpha: 0.7),
                              )
                            : null),
                  ),
                  child: Center(
                    child: Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor,
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

    final leadingBlanks = days.first.date.weekday % 7;
    final cells = <WirdDayProgress?>[
      ...List<WirdDayProgress?>.filled(leadingBlanks, null),
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
            final showLabel =
                weekdayIdx == 0 || weekdayIdx == 2 || weekdayIdx == 4;
            return SizedBox(
              height: 28,
              width: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: showLabel
                    ? Text(
                        _sundayFirstLabels[weekdayIdx],
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
                    final cellColor = _colorForDay(item, colors, theme);
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
                                : (!item.isApplicable
                                    ? Border.all(
                                        color: colors.cardBorder
                                            .withValues(alpha: 0.7),
                                      )
                                    : null),
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
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;

  const _LegendItem({
    required this.color,
    this.borderColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null ? Border.all(color: borderColor!) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.mutedText,
          ),
        ),
      ],
    );
  }
}

class _WirdSelectedDayStrip extends StatelessWidget {
  final WirdDayProgress day;
  final VoidCallback onViewDay;

  const _WirdSelectedDayStrip({
    required this.day,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    final String statusLabel;
    if (!day.isApplicable) {
      statusLabel = 'Not scheduled';
    } else {
      switch (day.status) {
        case AwradStatus.done:
          statusLabel = 'Done';
        case AwradStatus.halfDone:
          statusLabel = 'Half done';
        case AwradStatus.notDone:
          statusLabel = 'Not done';
      }
    }

    final trimmedNote = day.note?.trim();

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
                  formatFriendlyDate(day.date),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  formatHijriDate(day.date),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: day.isApplicable && day.status != AwradStatus.notDone
                        ? colors.emerald
                        : colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trimmedNote != null && trimmedNote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trimmedNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
