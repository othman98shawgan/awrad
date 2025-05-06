import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/task_service.dart';
import 'selected_date_provider.dart';

final tasksProvider = StateNotifierProvider.autoDispose.family<TaskNotifier, List<Map<String, dynamic>>, DateTime>(
  (ref, date) {
    return TaskNotifier(date);
  },
);

class TaskNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final DateTime date;
  TaskNotifier(this.date) : super([]) {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final loaded = await TaskService.loadTasks(date);
    state = loaded.isNotEmpty ? loaded : _defaultTasks();
  }

  Future<void> toggleTask(int index, bool? value) async {
    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index) {...state[i], 'done': value} else state[i],
    ];
    await TaskService.saveTasks(date, state);
  }

  List<Map<String, dynamic>> _defaultTasks() => [
        {'title': 'Read Quran', 'done': false},
        {'title': 'Fajr prayer in congregation', 'done': false},
        {'title': 'Duha prayer', 'done': false},
        {'title': 'Morning adhkar', 'done': false},
        {'title': 'Evening adhkar', 'done': false},
        {'title': '200 times istighfar', 'done': false},
        {'title': '200 times “La ilaha illa Allah”', 'done': false},
        {'title': '200 blessings on the Prophet', 'done': false},
        {'title': 'Fasting', 'done': false},
        {'title': 'Read for half an hour', 'done': false},
        {'title': 'Remember the Hereafter', 'done': false},
        {'title': 'Spiritual connection with dawah', 'done': false},
      ];
}
