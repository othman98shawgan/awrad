import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/prayer_item.dart';
import '../../services/date_utils.dart';
import '../../services/prayer_provider.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/date_switcher_bar.dart';
import '../widgets/prayer_card.dart';

class PrayerProgressPage extends ConsumerStatefulWidget {
  const PrayerProgressPage({super.key});

  static const int initialPage = 10000;

  @override
  ConsumerState<PrayerProgressPage> createState() => _PrayerProgressPageState();
}

class _PrayerProgressPageState extends ConsumerState<PrayerProgressPage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    final today = normalizeDate(DateTime.now());
    final selected = ref.read(selectedDateProvider);
    final offset = selected.difference(today).inDays;
    _controller =
        PageController(initialPage: PrayerProgressPage.initialPage + offset);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = normalizeDate(DateTime.now());

    ref.listen<DateTime>(selectedDateProvider, (_, next) {
      final offset = normalizeDate(next).difference(today).inDays;
      final targetPage = PrayerProgressPage.initialPage + offset;

      if (_controller.hasClients && _controller.page?.round() != targetPage) {
        _controller.jumpToPage(targetPage);
      }
    });

    return Column(
      children: [
        DateSwitcherBar(
          onPrevious: () {
            _controller.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
          onNext: () {
            _controller.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (pageIndex) {
              final offset = pageIndex - PrayerProgressPage.initialPage;
              final newDate =
                  DateTime(today.year, today.month, today.day + offset);
              ref.read(selectedDateProvider.notifier).selectDate(newDate);
            },
            itemBuilder: (context, pageIndex) {
              final offset = pageIndex - PrayerProgressPage.initialPage;
              final pageDate =
                  DateTime(today.year, today.month, today.day + offset);
              return _DailyPrayerView(pageDate: pageDate);
            },
          ),
        ),
      ],
    );
  }
}

class _DailyPrayerView extends ConsumerWidget {
  final DateTime pageDate;

  const _DailyPrayerView({required this.pageDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayers = ref.watch(prayerListProvider(pageDate));
    final notifier = ref.read(prayerListProvider(pageDate).notifier);
    final log = DailyPrayerLog(
      dateKey: formatDateKey(pageDate),
      prayers: prayers,
    );

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _DailyPrayerStatusCard(log: log),
        const SizedBox(height: 12),
        for (int i = 0; i < prayers.length; i++) ...[
          PrayerCard(
            prayer: prayers[i],
            onToggleAll: (mark) => notifier.toggleMain(i, mark),
            onSelectHome: () => notifier.markAtHome(i),
            onSelectMasjid: () => notifier.toggleInMasjid(i, true),
            onToggleFard: (v) => notifier.toggleFard(i, v),
            onToggleBeforeSunnah: (v) => notifier.toggleBeforeSunnah(i, v),
            onToggleSunnah: (v) => notifier.toggleSunnah(i, v),
            onToggleWitr: (v) => notifier.toggleWitr(i, v),
          ),
          if (i < prayers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DailyPrayerStatusCard extends StatelessWidget {
  final DailyPrayerLog log;

  const _DailyPrayerStatusCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final total = log.totalPrayers;
    final done = log.completedPrayers;
    final half = log.halfDonePrayers;
    final percent = (log.completionScore * 100).round();

    final doneFrac = total == 0 ? 0.0 : done / total;
    final halfFrac = total == 0 ? 0.0 : half / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Prayer Status",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.emeraldSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      color: colors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (doneFrac > 0)
                      Expanded(
                        flex: (doneFrac * 1000).round(),
                        child: Container(color: colors.emerald),
                      ),
                    if (halfFrac > 0)
                      Expanded(
                        flex: (halfFrac * 1000).round(),
                        child: Container(color: colors.amber),
                      ),
                    if ((1 - doneFrac - halfFrac) > 0.001)
                      Expanded(
                        flex: ((1 - doneFrac - halfFrac) * 1000).round(),
                        child: Container(color: colors.heatmapLevels[0]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Prayers',
                    value: '$done / $total',
                    accentColor: colors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'In Masjid',
                    value: '${log.inMasjidCount} / $total',
                    accentColor: colors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatTile(
                    label: 'Rak‘ahs',
                    value: '${log.completedRakahs} / ${log.totalRakahs}',
                    accentColor: colors.emerald,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.emeraldSoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
