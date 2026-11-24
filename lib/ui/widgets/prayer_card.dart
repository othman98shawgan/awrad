import 'package:flutter/material.dart';

import '../../models/awrad_status.dart';
import '../../models/prayer_item.dart';
import '../theme/app_theme.dart';

/// Serene Oasis prayer card with a circular tri-state toggle, dedicated
/// In Masjid icon button in the header (which tints the card in emerald),
/// and direct one-tap chips for Sunnah, Fard, and Witr rak‘ahs.
class PrayerCard extends StatelessWidget {
  final PrayerItem prayer;
  final ValueChanged<bool> onToggleAll;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectMasjid;
  final ValueChanged<bool> onToggleFard;
  final ValueChanged<bool> onToggleBeforeSunnah;
  final ValueChanged<bool> onToggleSunnah;
  final ValueChanged<bool> onToggleWitr;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onToggleAll,
    required this.onSelectHome,
    required this.onSelectMasjid,
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
    final inMasjid = prayer.inMasjid;

    final cardColor = inMasjid
        ? colors.emeraldSoft.withValues(alpha: 0.45)
        : theme.colorScheme.surface;
    final borderColor = inMasjid
        ? colors.emerald.withValues(alpha: 0.55)
        : isHalf
            ? colors.amber.withValues(alpha: 0.45)
            : colors.cardBorder;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: inMasjid ? 1.4 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                  '${prayer.completedRakahs}/${prayer.totalRakahs}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDone
                        ? colors.emerald
                        : isHalf
                            ? colors.amberText
                            : colors.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _PrayerLocationToggle(
                  prayerName: prayer.name,
                  fardDone: prayer.fardDone,
                  inMasjid: inMasjid,
                  onSelectHome: onSelectHome,
                  onSelectMasjid: onSelectMasjid,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (prayer.beforeSunnah > 0)
                  _SegmentChip(
                    label: 'Sunnah (${prayer.beforeSunnah})',
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

class _PrayerLocationToggle extends StatelessWidget {
  final String prayerName;
  final bool fardDone;
  final bool inMasjid;
  final VoidCallback onSelectHome;
  final VoidCallback onSelectMasjid;

  const _PrayerLocationToggle({
    required this.prayerName,
    required this.fardDone,
    required this.inMasjid,
    required this.onSelectHome,
    required this.onSelectMasjid,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final homeSelected = fardDone && !inMasjid;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: inMasjid ? colors.emerald.withValues(alpha: 0.5) : colors.cardBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Prayed at home',
            child: Semantics(
              button: true,
              label: '$prayerName at home',
              child: InkWell(
                onTap: onSelectHome,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: homeSelected
                        ? theme.colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: homeSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    homeSelected ? Icons.home_rounded : Icons.home_outlined,
                    size: 22,
                    color: homeSelected
                        ? theme.colorScheme.onSurface
                        : colors.mutedText,
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: 'Prayed in Masjid',
            child: Semantics(
              button: true,
              label: '$prayerName in Masjid',
              child: InkWell(
                onTap: onSelectMasjid,
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: inMasjid ? colors.emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    inMasjid ? Icons.mosque_rounded : Icons.mosque_outlined,
                    size: 22,
                    color: inMasjid ? Colors.white : colors.mutedText,
                  ),
                ),
              ),
            ),
          ),
        ],
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
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
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
