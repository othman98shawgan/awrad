import 'package:flutter/material.dart';

import '../../models/awrad_status.dart';
import '../../models/prayer_item.dart';
import '../theme/app_theme.dart';

/// Serene Oasis prayer card with a circular tri-state toggle and direct
/// one-tap chips for In Masjid, Fard, Before Sunnah, Sunnah, and Witr.
class PrayerCard extends StatelessWidget {
  final PrayerItem prayer;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<bool> onToggleInMasjid;
  final ValueChanged<bool> onToggleFard;
  final ValueChanged<bool> onToggleBeforeSunnah;
  final ValueChanged<bool> onToggleSunnah;
  final ValueChanged<bool> onToggleWitr;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onToggleAll,
    required this.onToggleInMasjid,
    required this.onToggleFard,
    required this.onToggleBeforeSunnah,
    required this.onToggleSunnah,
    required this.onToggleWitr,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final status = prayer.status;
    final isDone = status == AwradStatus.done;
    final isHalf = status == AwradStatus.halfDone;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isHalf ? colors.amber.withValues(alpha: 0.45) : colors.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PrayerTriStateToggle(
                  status: status,
                  prayerName: prayer.name,
                  onTap: () => onToggleAll(!isDone),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    prayer.witr > 0 ? '${prayer.name} & Witr' : prayer.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? colors.mutedText
                          : theme.colorScheme.onSurface,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Text(
                  '${prayer.completedRakahs}/${prayer.totalRakahs} rak‘ahs',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDone
                        ? colors.emerald
                        : isHalf
                            ? colors.amberText
                            : colors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SegmentChip(
                  label: 'In Masjid',
                  icon: Icons.mosque_outlined,
                  selected: prayer.inMasjid,
                  onTap: () => onToggleInMasjid(!prayer.inMasjid),
                ),
                if (prayer.beforeSunnah > 0)
                  _SegmentChip(
                    label: 'Before Sunnah (${prayer.beforeSunnah})',
                    selected: prayer.beforeSunnahDone,
                    onTap: () => onToggleBeforeSunnah(!prayer.beforeSunnahDone),
                  ),
                _SegmentChip(
                  label: 'Fard (${prayer.fard})',
                  selected: prayer.fardDone,
                  onTap: () => onToggleFard(!prayer.fardDone),
                ),
                if (prayer.sunnah > 0)
                  _SegmentChip(
                    label: 'Sunnah (${prayer.sunnah})',
                    selected: prayer.sunnahDone,
                    onTap: () => onToggleSunnah(!prayer.sunnahDone),
                  ),
                if (prayer.witr > 0)
                  _SegmentChip(
                    label: 'Witr (${prayer.witr})',
                    selected: prayer.witrDone,
                    onTap: () => onToggleWitr(!prayer.witrDone),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerTriStateToggle extends StatelessWidget {
  final AwradStatus status;
  final String prayerName;
  final VoidCallback onTap;

  const _PrayerTriStateToggle({
    required this.status,
    required this.prayerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final isDone = status == AwradStatus.done;
    final isHalf = status == AwradStatus.halfDone;

    return Semantics(
      button: true,
      label: 'Toggle $prayerName',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? colors.emerald
                  : isHalf
                      ? colors.amberSoft
                      : Colors.transparent,
              border: Border.all(
                color: isDone
                    ? colors.emerald
                    : isHalf
                        ? colors.amber
                        : colors.cardBorder,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : isHalf
                    ? Icon(Icons.remove_rounded, size: 16, color: colors.amber)
                    : null,
          ),
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Material(
      color: selected
          ? colors.emeraldSoft
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.emerald.withValues(alpha: 0.45)
                  : colors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? colors.emerald : colors.mutedText,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.emerald : colors.mutedText,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: colors.emerald,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
