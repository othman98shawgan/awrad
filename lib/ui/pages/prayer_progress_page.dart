import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_status.dart';
import '../../services/date_utils.dart';
import '../../services/prayer_provider.dart';
import '../../services/selected_date_provider.dart';

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
    _controller = PageController(initialPage: PrayerProgressPage.initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = normalizeDate(DateTime.now());
    final date = ref.watch(selectedDateProvider);

    ref.listen<DateTime>(selectedDateProvider, (_, next) {
      final offset = normalizeDate(next).difference(today).inDays;
      final targetPage = PrayerProgressPage.initialPage + offset;

      if (_controller.hasClients && _controller.page?.round() != targetPage) {
        _controller.jumpToPage(targetPage);
      }
    });

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                _controller.previousPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuad,
                );
              },
            ),
            Text(
              formatDateKey(date),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                _controller.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutQuad,
                );
              },
            ),
          ],
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (pageIndex) {
          final offset = pageIndex - PrayerProgressPage.initialPage;
          final newDate = DateTime(today.year, today.month, today.day + offset);
          ref.read(selectedDateProvider.notifier).selectDate(newDate);
        },
        itemBuilder: (context, pageIndex) {
          final offset = pageIndex - PrayerProgressPage.initialPage;
          final pageDate = DateTime(today.year, today.month, today.day + offset);

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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: prayers.length,
                    itemBuilder: (context, i) {
                      final p = prayers[i];
                      return ExpansionTile(
                        leading: Checkbox(
                          tristate: true,
                          value: p.done,
                          onChanged: (v) => notifier.toggleMain(i, v),
                          activeColor: p.status == AwradStatus.halfDone
                              ? Colors.amber[700]
                              : Colors.green,
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            decoration: p.status == AwradStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: p.status == AwradStatus.done
                                ? Colors.grey
                                : null,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 72.0),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: const Text('In Masjid'),
                                  value: p.inMasjid,
                                  onChanged: (v) =>
                                      notifier.toggleInMasjid(i, v!),
                                  activeColor: Colors.green,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: Text('Fard (${p.fard} rak‘ahs)'),
                                  value: p.fardDone,
                                  onChanged: (v) => notifier.toggleFard(i, v!),
                                  activeColor: Colors.green,
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
                                    onChanged: (v) =>
                                        notifier.toggleBeforeSunnah(i, v!),
                                    activeColor: Colors.green,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                CheckboxListTile(
                                  title: Text('Sunnah (${p.sunnah} rak‘ahs)'),
                                  value: p.sunnahDone,
                                  onChanged: (v) =>
                                      notifier.toggleSunnah(i, v!),
                                  activeColor: Colors.green,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                if (p.witr > 0)
                                  CheckboxListTile(
                                    title: Text('Witr (${p.witr} rak‘ahs)'),
                                    value: p.witrDone,
                                    onChanged: (v) =>
                                        notifier.toggleWitr(i, v!),
                                    activeColor: Colors.green,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Prayers completed: $completedPrayers of $totalPrayers'),
                    Text('In masjid: $masjidPrayers of $totalPrayers'),
                    Text('Rak‘ahs done: $completedRakahs of $totalRakahs'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
