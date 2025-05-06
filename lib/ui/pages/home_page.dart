import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/selected_date_provider.dart';
import '../../services/task_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  static const int initialPage = 10000;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    final initialDate = today;

    _controller = PageController(
      initialPage: HomePage.initialPage,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool? _nextState(bool? current) {
    if (current == false) return true;
    if (current == true) return null;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final date = ref.watch(selectedDateProvider);

    final offset = date.difference(DateTime(today.year, today.month, today.day)).inDays;
    final targetPage = HomePage.initialPage + offset;

    // 🚨 Correct place to listen
    ref.listen<DateTime>(selectedDateProvider, (previous, next) {
      final today = DateTime.now();
      final offset = next.difference(DateTime(today.year, today.month, today.day)).inDays;
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
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
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
          final newDate = DateTime(today.year, today.month, today.day).add(Duration(days: offset));
          ref.read(selectedDateProvider.notifier).state = newDate;
        },
        itemBuilder: (context, pageIndex) {
          final offset = pageIndex - HomePage.initialPage;
          final pageDate = DateTime(today.year, today.month, today.day).add(Duration(days: offset));

          final tasks = ref.watch(tasksProvider(pageDate));
          final completed = tasks.where((t) => t['done'] == true).length;
          final taskNotifier = ref.read(tasksProvider(pageDate).notifier);

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
                      final done = task['done'] as bool?;

                      return CheckboxListTile(
                        tristate: true,
                        activeColor: Colors.green,
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            decoration: done == true ? TextDecoration.lineThrough : null,
                            color: done == true ? Colors.grey : null,
                          ),
                        ),
                        value: done,
                        onChanged: (_) {
                          if (taskNotifier.mounted) {
                            final next = _nextState(done);
                            taskNotifier.toggleTask(idx, next);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "$completed of ${tasks.length} tasks completed",
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
