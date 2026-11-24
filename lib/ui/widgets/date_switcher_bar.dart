import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/date_utils.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';

/// Shared floating date navigation bar synced with [selectedDateProvider].
/// Supports prev/next day stepping, tapping to open a calendar picker, and
/// a one-tap "Today" return pill when viewing another date.
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
    final isToday = date == today;
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
            if (!isToday)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: colors.emeraldSoft,
                    foregroundColor: colors.emerald,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () =>
                      ref.read(selectedDateProvider.notifier).goToToday(),
                  child: const Text(
                    'Today',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
