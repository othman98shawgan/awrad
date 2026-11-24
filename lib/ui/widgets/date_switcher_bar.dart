import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/date_utils.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';

/// Custom calendar icon button displaying today's day-of-month number.
/// Tapping jumps [selectedDateProvider] directly back to today.
class TodayCalendarButton extends ConsumerWidget {
  const TodayCalendarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final today = normalizeDate(DateTime.now());
    final isToday = selected == today;
    final colors = context.awradColors;

    final borderColor = isToday ? colors.cardBorder : colors.emerald;
    final headerColor = isToday ? colors.mutedText : colors.emerald;
    final bgColor = isToday
        ? Theme.of(context).colorScheme.surface
        : colors.emeraldSoft;
    final numberColor =
        isToday ? Theme.of(context).colorScheme.onSurface : colors.emerald;

    return IconButton(
      tooltip: 'Go to today',
      onPressed: isToday
          ? null
          : () => ref.read(selectedDateProvider.notifier).goToToday(),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              color: headerColor,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${today.day}',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: numberColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared floating date navigation bar synced with [selectedDateProvider].
/// Supports prev/next day stepping and tapping the date to open a calendar picker.
class DateSwitcherBar extends ConsumerWidget {
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const DateSwitcherBar({
    super.key,
    this.onPrevious,
    this.onNext,
  });

  static Future<void> openCalendarPicker(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(selectedDateProvider);
    final today = normalizeDate(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(today.year + 1, 12, 31),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final today = normalizeDate(DateTime.now());
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onPrevious ??
                  () => ref.read(selectedDateProvider.notifier).stepDays(-1),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => openCalendarPicker(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              formatFriendlyDate(date, now: today),
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colors.emerald,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Swipe days or tap for calendar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext ??
                  () => ref.read(selectedDateProvider.notifier).stepDays(1),
            ),
          ],
        ),
      ),
    );
  }
}
