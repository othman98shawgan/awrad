import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/progress_provider.dart';
import '../theme/app_theme.dart';

/// Builds a clean plain-text Awrad summary for elapsed days in the selected period.
String formatAwradReportText({
  required String periodLabel,
  required List<DailyProgressSummary> elapsedDays,
  required List<AwradTaskSummary> taskSummaries,
  required int streakDays,
}) {
  final totalDays = elapsedDays.length;
  final activeDays = elapsedDays.where((d) => d.awradScore > 0).length;
  final awradPct = totalDays == 0
      ? 0
      : ((elapsedDays.fold<double>(0.0, (s, d) => s + d.awradScore) /
                  totalDays) *
              100)
          .round();

  final lines = <String>[
    'Awrad Report — $periodLabel',
    'Active days: $activeDays / $totalDays | Streak: $streakDays days',
    '• Overall completion: $awradPct%',
  ];

  if (taskSummaries.isNotEmpty) {
    lines.add('');
    lines.add('All Awrad:');
    for (final task in taskSummaries) {
      final pct = (task.completionRate * 100).round();
      final detail = task.halfDays > 0
          ? '${task.doneDays} done, ${task.halfDays} half / ${task.applicableDays}d ($pct%)'
          : '${task.doneDays} / ${task.applicableDays}d ($pct%)';
      lines.add('• ${task.title}: $detail');
    }
  }

  return lines.join('\n');
}

/// Builds a clean plain-text Prayers summary for elapsed days in the selected period.
String formatPrayersReportText({
  required String periodLabel,
  required List<DailyProgressSummary> elapsedDays,
  required List<PrayerPeriodSummary> prayerSummaries,
}) {
  final totalDays = elapsedDays.length;
  final maxFard = totalDays * 5;
  final totalFard = elapsedDays.fold<int>(0, (s, d) => s + d.prayersDone);
  final fardPct = maxFard == 0 ? 0 : ((totalFard / maxFard) * 100).round();

  final totalMasjid = elapsedDays.fold<int>(0, (s, d) => s + d.prayersInMasjid);
  final masjidPct = maxFard == 0 ? 0 : ((totalMasjid / maxFard) * 100).round();

  final completedRakahs =
      elapsedDays.fold<int>(0, (s, d) => s + d.completedRakahs);
  final totalRakahs = elapsedDays.fold<int>(0, (s, d) => s + d.totalRakahs);
  final rakahPct =
      totalRakahs == 0 ? 0 : ((completedRakahs / totalRakahs) * 100).round();

  final lines = <String>[
    'Prayers Report — $periodLabel',
    'Days counted: $totalDays',
    '• Fard prayers: $totalFard / $maxFard ($fardPct%)',
    '• In Masjid: $totalMasjid / $maxFard ($masjidPct%)',
    '• Total rak‘ahs: $completedRakahs / $totalRakahs ($rakahPct%)',
  ];

  if (prayerSummaries.isNotEmpty) {
    lines.add('');
    lines.add('By Prayer:');
    for (final p in prayerSummaries) {
      lines.add(
        '• ${p.name}: ${p.fardDoneCount}/${p.daysCount} Fard · ${p.inMasjidCount} Masjid · ${p.completedRakahs}/${p.totalRakahs} rak‘ahs',
      );
    }
  }

  return lines.join('\n');
}

/// Opens the Awrad Report modal sheet.
Future<void> showAwradReportSheet(
  BuildContext context, {
  required String periodLabel,
  required List<DailyProgressSummary> elapsedDays,
  required List<AwradTaskSummary> taskSummaries,
  required int streakDays,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AwradReportSheet(
      periodLabel: periodLabel,
      elapsedDays: elapsedDays,
      taskSummaries: taskSummaries,
      streakDays: streakDays,
    ),
  );
}

/// Opens the Prayers Report modal sheet.
Future<void> showPrayersReportSheet(
  BuildContext context, {
  required String periodLabel,
  required List<DailyProgressSummary> elapsedDays,
  required List<PrayerPeriodSummary> prayerSummaries,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PrayersReportSheet(
      periodLabel: periodLabel,
      elapsedDays: elapsedDays,
      prayerSummaries: prayerSummaries,
    ),
  );
}

class _AwradReportSheet extends StatelessWidget {
  final String periodLabel;
  final List<DailyProgressSummary> elapsedDays;
  final List<AwradTaskSummary> taskSummaries;
  final int streakDays;

  const _AwradReportSheet({
    required this.periodLabel,
    required this.elapsedDays,
    required this.taskSummaries,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reportText = formatAwradReportText(
      periodLabel: periodLabel,
      elapsedDays: elapsedDays,
      taskSummaries: taskSummaries,
      streakDays: streakDays,
    );

    final totalDays = elapsedDays.length;
    final awradRate = totalDays == 0
        ? 0.0
        : elapsedDays.fold<double>(0.0, (s, d) => s + d.awradScore) / totalDays;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    'Awrad Report',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$periodLabel · $totalDays ${totalDays == 1 ? 'day' : 'days'} · $streakDays day streak',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReportMetricBar(
                    label: 'Overall Awrad Completion',
                    detail: '${(awradRate * 100).round()}%',
                    progress: awradRate,
                  ),
                  if (taskSummaries.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'All Awrad',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final task in taskSummaries) ...[
                      _ReportMetricBar(
                        label: task.title,
                        detail: task.halfDays > 0
                            ? '${task.doneDays} + ${task.halfDays}½ / ${task.applicableDays}d'
                            : '${task.doneDays} / ${task.applicableDays}d (${(task.completionRate * 100).round()}%)',
                        progress: task.completionRate,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
            _CopyReportFooter(
              label: 'Copy Awrad Report',
              reportText: reportText,
            ),
          ],
        );
      },
    );
  }
}

class _PrayersReportSheet extends StatelessWidget {
  final String periodLabel;
  final List<DailyProgressSummary> elapsedDays;
  final List<PrayerPeriodSummary> prayerSummaries;

  const _PrayersReportSheet({
    required this.periodLabel,
    required this.elapsedDays,
    required this.prayerSummaries,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reportText = formatPrayersReportText(
      periodLabel: periodLabel,
      elapsedDays: elapsedDays,
      prayerSummaries: prayerSummaries,
    );

    final totalDays = elapsedDays.length;
    final maxFard = totalDays * 5;
    final totalFard = elapsedDays.fold<int>(0, (s, d) => s + d.prayersDone);
    final fardRate = maxFard == 0 ? 0.0 : totalFard / maxFard;
    final totalMasjid =
        elapsedDays.fold<int>(0, (s, d) => s + d.prayersInMasjid);
    final masjidRate = maxFard == 0 ? 0.0 : totalMasjid / maxFard;
    final completedRakahs =
        elapsedDays.fold<int>(0, (s, d) => s + d.completedRakahs);
    final totalRakahs = elapsedDays.fold<int>(0, (s, d) => s + d.totalRakahs);
    final rakahRate = totalRakahs == 0 ? 0.0 : completedRakahs / totalRakahs;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  Text(
                    'Prayers Report',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$periodLabel · $totalDays ${totalDays == 1 ? 'day' : 'days'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ReportMetricBar(
                    label: 'Five Daily Prayers (Fard)',
                    detail:
                        '$totalFard / $maxFard (${(fardRate * 100).round()}%)',
                    progress: fardRate,
                  ),
                  const SizedBox(height: 12),
                  _ReportMetricBar(
                    label: 'Prayed in Masjid',
                    detail:
                        '$totalMasjid / $maxFard (${(masjidRate * 100).round()}%)',
                    progress: masjidRate,
                  ),
                  const SizedBox(height: 12),
                  _ReportMetricBar(
                    label: 'Total Rak‘ahs (Fard & Sunnah)',
                    detail:
                        '$completedRakahs / $totalRakahs (${(rakahRate * 100).round()}%)',
                    progress: rakahRate,
                  ),
                  if (prayerSummaries.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'By Prayer',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final p in prayerSummaries) ...[
                      _ReportMetricBar(
                        label: p.name,
                        detail:
                            '${p.fardDoneCount}/${p.daysCount} Fard · ${p.inMasjidCount} Masjid · ${p.completedRakahs}/${p.totalRakahs} r',
                        progress: p.fardRate,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
            _CopyReportFooter(
              label: 'Copy Prayers Report',
              reportText: reportText,
            ),
          ],
        );
      },
    );
  }
}

class _CopyReportFooter extends StatelessWidget {
  final String label;
  final String reportText;

  const _CopyReportFooter({
    required this.label,
    required this.reportText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: reportText));
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: Text(label),
        ),
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
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
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
