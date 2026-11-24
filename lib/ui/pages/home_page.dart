import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_status.dart';
import '../../services/awrad_provider.dart';
import '../../services/date_utils.dart';
import '../../services/selected_date_provider.dart';

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
    _controller = PageController(initialPage: HomePage.initialPage);
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
      final targetPage = HomePage.initialPage + offset;

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
          final offset = pageIndex - HomePage.initialPage;
          final newDate = DateTime(today.year, today.month, today.day + offset);
          ref.read(selectedDateProvider.notifier).selectDate(newDate);
        },
        itemBuilder: (context, pageIndex) {
          final offset = pageIndex - HomePage.initialPage;
          final pageDate = DateTime(today.year, today.month, today.day + offset);

          final allTasks = ref.watch(awradTasksProvider);
          final tasks = allTasks.where((t) => t.appliesTo(pageDate)).toList();
          final log = ref.watch(dailyAwradLogProvider(pageDate));
          final logNotifier = ref.read(dailyAwradLogProvider(pageDate).notifier);

          final completed = tasks
              .where((t) => log.statusFor(t.id) == AwradStatus.done)
              .length;
          final halfDone = tasks
              .where((t) => log.statusFor(t.id) == AwradStatus.halfDone)
              .length;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, idx) {
                      final task = tasks[idx];
                      final status = log.statusFor(task.id);

                      return CheckboxListTile(
                        tristate: true,
                        activeColor: status == AwradStatus.halfDone
                            ? Colors.amber[700]
                            : Colors.green,
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: status == AwradStatus.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: status == AwradStatus.done
                                ? Colors.grey
                                : null,
                          ),
                        ),
                        value: status.toTristate(),
                        onChanged: (_) {
                          logNotifier.cycleTaskStatus(task.id);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  halfDone > 0
                      ? '$completed of ${tasks.length} tasks completed ($halfDone half done)'
                      : '$completed of ${tasks.length} tasks completed',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    7,
                    (_) => Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
