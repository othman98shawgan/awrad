import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/progress_provider.dart';
import '../theme/app_theme.dart';

/// Builds a clean plain-text weekly/monthly summary suitable for sharing
/// with a Quran/spiritual teacher via WhatsApp or email.
String formatTeacherReportText({
  required String periodLabel,
  required List<DailyProgressSummary> days,
  required int streakDays,
}) {
  final totalDays = days.length;
  final activeDays =
      days.where((d) => d.awradScore > 0 || d.prayersDone > 0).length;

  final awradPct = totalDays == 0
      ? 0
      : ((days.fold<double>(0.0, (s, d) => s + d.awradScore) / totalDays) * 100)
          .round();

  final totalFard = days.fold<int>(0, (s, d) => s + d.prayersDone);
  final maxFard = totalDays * 5;
  final fardPct = maxFard == 0 ? 0 : ((totalFard / maxFard) * 100).round();

  final totalMasjid = days.fold<int>(0, (s, d) => s + d.prayersInMasjid);
  final masjidPct = maxFard == 0 ? 0 : ((totalMasjid / maxFard) * 100).round();

  final completedRakahs = days.fold<int>(0, (s, d) => s + d.completedRakahs);
  final totalRakahs = days.fold<int>(0, (s, d) => s + d.totalRakahs);
  final rakahPct =
      totalRakahs == 0 ? 0 : ((completedRakahs / totalRakahs) * 100).round();

  return [
    'Awrad Progress Report — $periodLabel',
    'Active days: $activeDays / $totalDays | Streak: $streakDays days',
    '• Awrad completion: $awradPct%',
    '• Fard prayers: $totalFard / $maxFard ($fardPct%)',
    '• In Masjid: $totalMasjid / $maxFard ($masjidPct%)',
    '• Total rak‘ahs: $completedRakahs / $totalRakahs ($rakahPct%)',
  ].join('\n');
}

/// Opens a clean preview & copy-to-clipboard bottom sheet for the Teacher Report.
Future<void> showTeacherReportSheet(
  BuildContext context, {
  required String periodLabel,
  required List<DailyProgressSummary> days,
  required int streakDays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _TeacherReportSheet(
      periodLabel: periodLabel,
      days: days,
      streakDays: streakDays,
    ),
  );
}

class _TeacherReportSheet extends StatelessWidget {
  final String periodLabel;
  final List<DailyProgressSummary> days;
  final int streakDays;

  const _TeacherReportSheet({
    required this.periodLabel,
    required this.days,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reportText = formatTeacherReportText(
      periodLabel: periodLabel,
      days: days,
      streakDays: streakDays,
    );

    final totalDays = days.length;
    final awradRate = totalDays == 0
        ? 0.0
        : days.fold<double>(0.0, (s, d) => s + d.awradScore) / totalDays;
    final totalFard = days.fold<int>(0, (s, d) => s + d.prayersDone);
    final maxFard = totalDays * 5;
    final fardRate = maxFard == 0 ? 0.0 : totalFard / maxFard;
    final totalMasjid = days.fold<int>(0, (s, d) => s + d.prayersInMasjid);
    final masjidRate = maxFard == 0 ? 0.0 : totalMasjid / maxFard;
    final completedRakahs = days.fold<int>(0, (s, d) => s + d.completedRakahs);
    final totalRakahs = days.fold<int>(0, (s, d) => s + d.totalRakahs);
    final rakahRate = totalRakahs == 0 ? 0.0 : completedRakahs / totalRakahs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Report',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$periodLabel · $streakDays day streak',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.mutedText,
            ),
          ),
          const SizedBox(height: 16),
          _ReportMetricBar(
            label: 'Awrad Completion',
            detail: '${(awradRate * 100).round()}%',
            progress: awradRate,
          ),
          const SizedBox(height: 12),
          _ReportMetricBar(
            label: 'Five Daily Prayers (Fard)',
            detail: '$totalFard / $maxFard (${(fardRate * 100).round()}%)',
            progress: fardRate,
          ),
          const SizedBox(height: 12),
          _ReportMetricBar(
            label: 'Prayed in Masjid',
            detail: '$totalMasjid / $maxFard (${(masjidRate * 100).round()}%)',
            progress: masjidRate,
          ),
          const SizedBox(height: 12),
          _ReportMetricBar(
            label: 'Total Rak‘ahs (Fard & Sunnah)',
            detail:
                '$completedRakahs / $totalRakahs (${(rakahRate * 100).round()}%)',
            progress: rakahRate,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: reportText));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Teacher report copied to clipboard.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('Copy Report for Teacher'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMetricBar extends StatelessWidget {
  final String label;
  final String detail;
  final double progress;

  const _ReportMetricBar({
    required this.label,
    required this.detail,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final clamped = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              detail,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.emerald,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: colors.heatmapLevels[0],
            valueColor: AlwaysStoppedAnimation(colors.emerald),
          ),
        ),
      ],
    );
  }
}
