import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_status.dart';
import '../../services/date_utils.dart';
import '../../services/prayer_provider.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/date_switcher_bar.dart';

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
    final colors = context.awradColors;

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

              final prayers = ref.watch(prayerListProvider(pageDate));
              final notifier = ref.read(prayerListProvider(pageDate).notifier);

              final totalPrayers = prayers.length;
              final completedPrayers =
                  prayers.where((p) => p.status == AwradStatus.done).length;
              final masjidPrayers = prayers.where((p) => p.inMasjid).length;
              final totalRakahs =
                  prayers.fold<int>(0, (sum, p) => sum + p.totalRakahs);
              final completedRakahs =
                  prayers.fold<int>(0, (sum, p) => sum + p.completedRakahs);

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: prayers.length,
                        itemBuilder: (context, i) {
                          final p = prayers[i];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              leading: Checkbox(
                                tristate: true,
                                value: p.done,
                                onChanged: (v) => notifier.toggleMain(i, v),
                                activeColor: p.status == AwradStatus.halfDone
                                    ? colors.amber
                                    : colors.emerald,
                              ),
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  decoration: p.status == AwradStatus.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: p.status == AwradStatus.done
                                      ? colors.mutedText
                                      : null,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 56,
                                    right: 16,
                                    bottom: 8,
                                  ),
                                  child: Column(
                                    children: [
                                      CheckboxListTile(
                                        title: const Text('In Masjid'),
                                        value: p.inMasjid,
                                        onChanged: (v) =>
                                            notifier.toggleInMasjid(i, v!),
                                        activeColor: colors.emerald,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      CheckboxListTile(
                                        title: Text('Fard (${p.fard} rak‘ahs)'),
                                        value: p.fardDone,
                                        onChanged: (v) =>
                                            notifier.toggleFard(i, v!),
                                        activeColor: colors.emerald,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      if (p.beforeSunnah > 0)
                                        CheckboxListTile(
                                          title: Text(
                                            'Before Sunnah (${p.beforeSunnah} rak‘ahs)',
                                          ),
                                          value: p.beforeSunnahDone,
                                          onChanged: (v) => notifier
                                              .toggleBeforeSunnah(i, v!),
                                          activeColor: colors.emerald,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      CheckboxListTile(
                                        title: Text(
                                          'Sunnah (${p.sunnah} rak‘ahs)',
                                        ),
                                        value: p.sunnahDone,
                                        onChanged: (v) =>
                                            notifier.toggleSunnah(i, v!),
                                        activeColor: colors.emerald,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      if (p.witr > 0)
                                        CheckboxListTile(
                                          title: Text(
                                            'Witr (${p.witr} rak‘ahs)',
                                          ),
                                          value: p.witrDone,
                                          onChanged: (v) =>
                                              notifier.toggleWitr(i, v!),
                                          activeColor: colors.emerald,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatPill(
                              label: 'Prayers',
                              value: '$completedPrayers/$totalPrayers',
                            ),
                            _StatPill(
                              label: 'In Masjid',
                              value: '$masjidPrayers/$totalPrayers',
                            ),
                            _StatPill(
                              label: 'Rak‘ahs',
                              value: '$completedRakahs/$totalRakahs',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.emerald,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.mutedText,
              ),
        ),
      ],
    );
  }
}
