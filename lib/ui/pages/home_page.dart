import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_status.dart';
import '../../services/awrad_provider.dart';
import '../../services/date_utils.dart';
import '../../services/selected_date_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/date_switcher_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  static const int initialPage = 10000;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    final today = normalizeDate(DateTime.now());
    final selected = ref.read(selectedDateProvider);
    final offset = selected.difference(today).inDays;
    _controller = PageController(initialPage: HomePage.initialPage + offset);
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
      final targetPage = HomePage.initialPage + offset;

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
              final offset = pageIndex - HomePage.initialPage;
              final newDate =
                  DateTime(today.year, today.month, today.day + offset);
              ref.read(selectedDateProvider.notifier).selectDate(newDate);
            },
            itemBuilder: (context, pageIndex) {
              final offset = pageIndex - HomePage.initialPage;
              final pageDate =
                  DateTime(today.year, today.month, today.day + offset);

              final allTasks = ref.watch(awradTasksProvider);
              final tasks =
                  allTasks.where((t) => t.appliesTo(pageDate)).toList();
              final log = ref.watch(dailyAwradLogProvider(pageDate));
              final logNotifier =
                  ref.read(dailyAwradLogProvider(pageDate).notifier);

              final completed = tasks
                  .where((t) => log.statusFor(t.id) == AwradStatus.done)
                  .length;
              final halfDone = tasks
                  .where((t) => log.statusFor(t.id) == AwradStatus.halfDone)
                  .length;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        physics: const ClampingScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final task = tasks[idx];
                          final status = log.statusFor(task.id);

                          return Card(
                            child: CheckboxListTile(
                              tristate: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              activeColor: status == AwradStatus.halfDone
                                  ? colors.amber
                                  : colors.emerald,
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  decoration: status == AwradStatus.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: status == AwradStatus.done
                                      ? colors.mutedText
                                      : null,
                                ),
                              ),
                              value: status.toTristate(),
                              onChanged: (_) {
                                logNotifier.cycleTaskStatus(task.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      halfDone > 0
                          ? '$completed of ${tasks.length} tasks completed · $halfDone half done'
                          : '$completed of ${tasks.length} tasks completed',
                      style: TextStyle(color: colors.mutedText),
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
