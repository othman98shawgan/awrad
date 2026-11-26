import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/date_utils.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';

/// Custom calendar icon button displaying today's day-of-month number.
/// Tapping jumps back to today (or the current week/month when [onPressed] is provided).
class TodayCalendarButton extends ConsumerWidget {
  final bool? isCurrentOverride;
  final VoidCallback? onPressedOverride;
  final String tooltip;

  const TodayCalendarButton({
    super.key,
    this.isCurrentOverride,
    this.onPressedOverride,
    this.tooltip = 'Go to today',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final today = normalizeDate(DateTime.now());
    final isCurrent = isCurrentOverride ?? (selected == today);
    final colors = context.awradColors;

    final borderColor = isCurrent ? colors.cardBorder : colors.emerald;
    final headerColor = isCurrent ? colors.mutedText : colors.emerald;
    final bgColor = isCurrent
        ? Theme.of(context).colorScheme.surface
        : colors.emeraldSoft;
    final numberColor =
        isCurrent ? Theme.of(context).colorScheme.onSurface : colors.emerald;

    return IconButton(
      tooltip: tooltip,
      onPressed: isCurrent
          ? null
          : (onPressedOverride ??
              () => ref.read(selectedDateProvider.notifier).goToToday()),
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
                          const SizedBox(width: 6),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: colors.emerald,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatHijriDate(date),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.mutedText,
                          fontWeight: FontWeight.w500,
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

/// A [PageScrollPhysics] tuned so light flicks and short drags (>15% width)
/// smoothly advance days without snapping back. Use with `pageSnapping: false`
/// on [PageView] so Flutter does not shadow this physics with default snapping.
class LightSwipePagePhysics extends PageScrollPhysics {
  const LightSwipePagePhysics({super.parent});

  @override
  LightSwipePagePhysics applyTo(ScrollPhysics? ancestor) {
    return LightSwipePagePhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 20.0;

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5,
        stiffness: 200.0,
        damping: 21.0,
      );

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    final viewport = position.viewportDimension;
    if (viewport <= 0) return position.pixels;

    final page = position.pixels / viewport;
    double targetPage;

    if (velocity > tolerance.velocity) {
      targetPage = page.floorToDouble() + 1.0;
    } else if (velocity < -tolerance.velocity) {
      targetPage = page.ceilToDouble() - 1.0;
    } else if (position is ScrollPosition) {
      if (position.userScrollDirection == ScrollDirection.reverse) {
        final frac = page - page.floorToDouble();
        targetPage =
            frac > 0.15 ? page.floorToDouble() + 1.0 : page.floorToDouble();
      } else if (position.userScrollDirection == ScrollDirection.forward) {
        final frac = page.ceilToDouble() - page;
        targetPage =
            frac > 0.15 ? page.ceilToDouble() - 1.0 : page.ceilToDouble();
      } else {
        targetPage = page.roundToDouble();
      }
    } else {
      targetPage = page.roundToDouble();
    }

    final minPage = position.minScrollExtent / viewport;
    final maxPage = position.maxScrollExtent / viewport;
    return targetPage.clamp(minPage, maxPage) * viewport;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if ((target - position.pixels).abs() < tolerance.distance &&
        velocity.abs() < tolerance.velocity) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}
