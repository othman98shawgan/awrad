import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/awrad_log.dart';
import '../models/awrad_status.dart';
import '../models/awrad_task.dart';
import '../models/awrad_template.dart';
import 'awrad_repository.dart';
import 'date_utils.dart';

final awradRepositoryProvider = Provider<AwradRepository>((ref) {
  return LocalAwradRepository();
});

/// Incremented whenever any daily Awrad log mutates so range summaries refresh.
final awradDataVersionProvider = StateProvider<int>((ref) => 0);

/// Manages the user's master list of Awrad task definitions.
final awradTasksProvider =
    StateNotifierProvider<AwradTasksNotifier, List<AwradTask>>((ref) {
  final repo = ref.watch(awradRepositoryProvider);
  return AwradTasksNotifier(repo);
});

class AwradTasksNotifier extends StateNotifier<List<AwradTask>> {
  final AwradRepository _repo;
  Future<void>? _loadFuture;

  AwradTasksNotifier(this._repo) : super(const []) {
    load();
  }

  Future<void> load() {
    return _loadFuture ??= _performLoad();
  }

  Future<void> _performLoad() async {
    final loaded = await _repo.loadTasks();
    if (!mounted) return;
    state = loaded;
  }

  Future<void> addTask({
    required String title,
    AwradCategory category = AwradCategory.other,
    Set<int> repeatWeekdays = const {},
    String? note,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final task = AwradTask(
      id: 'task_${now.microsecondsSinceEpoch}',
      title: trimmed,
      category: category,
      repeatWeekdays: repeatWeekdays,
      sortOrder: state.length,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    state = [...state, task];
    await _repo.saveTasks(state);
  }

  Future<void> updateTask(AwradTask updated) async {
    final now = DateTime.now();
    state = [
      for (final task in state)
        if (task.id == updated.id) updated.copyWith(updatedAt: now) else task,
    ];
    await _repo.saveTasks(state);
  }

  Future<void> deleteTask(String taskId) async {
    final remaining = state.where((t) => t.id != taskId).toList();
    state = _reindex(remaining);
    await _repo.saveTasks(state);
  }

  /// Restores a previously deleted [AwradTask] at its original [sortOrder].
  Future<void> restoreTask(AwradTask task) async {
    if (state.any((t) => t.id == task.id)) return;
    final updated = [...state];
    final insertAt = task.sortOrder.clamp(0, updated.length);
    updated.insert(insertAt, task);
    state = _reindex(updated);
    await _repo.saveTasks(state);
  }

  Future<void> reorderTasks(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= state.length) return;
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (targetIndex < 0 || targetIndex >= state.length) return;

    final updated = [...state];
    final moved = updated.removeAt(oldIndex);
    updated.insert(targetIndex, moved);
    state = _reindex(updated);
    await _repo.saveTasks(state);
  }

  /// Imports a curated [AwradTemplate] by either replacing or merging with existing tasks.
  Future<void> importTemplate(
    AwradTemplate template, {
    bool replace = false,
  }) async {
    if (replace) {
      state = LocalAwradRepository.buildTasksFromTemplate(template);
    } else {
      final existingTitles = state.map((t) => t.title.toLowerCase().trim()).toSet();
      final freshItems = template.tasks
          .where((t) => !existingTitles.contains(t.title.toLowerCase().trim()))
          .toList();
      final filteredTemplate = AwradTemplate(
        id: template.id,
        name: template.name,
        description: template.description,
        tasks: freshItems,
      );
      final added = LocalAwradRepository.buildTasksFromTemplate(
        filteredTemplate,
        startSortOrder: state.length,
      );
      state = [...state, ...added];
    }
    await _repo.saveTasks(state);
  }

  List<AwradTask> _reindex(List<AwradTask> list) {
    return List.generate(
      list.length,
      (i) => list[i].copyWith(sortOrder: i),
    );
  }
}

/// Loads and updates per-day Awrad completion logs for a normalized [DateTime].
final dailyAwradLogProvider = StateNotifierProvider.autoDispose
    .family<DailyAwradLogNotifier, DailyAwradLog, DateTime>((ref, date) {
  final repo = ref.watch(awradRepositoryProvider);
  return DailyAwradLogNotifier(
    repo,
    normalizeDate(date),
    onMutated: () => ref.read(awradDataVersionProvider.notifier).state++,
  );
});

class DailyAwradLogNotifier extends StateNotifier<DailyAwradLog> {
  final AwradRepository _repo;
  final DateTime date;
  final void Function()? _onMutated;

  DailyAwradLogNotifier(
    this._repo,
    this.date, {
    void Function()? onMutated,
  })  : _onMutated = onMutated,
        super(
          _repo.getCachedLog(date) ?? DailyAwradLog(dateKey: formatDateKey(date)),
        ) {
    if (_repo.getCachedLog(date) == null) {
      _load();
    }
  }

  Future<void> _load() async {
    final loaded = await _repo.loadLog(date);
    if (!mounted) return;
    state = loaded;
  }

  Future<void> setTaskStatus(String taskId, AwradStatus status) async {
    final existing = state.entries[taskId];
    final entry = AwradTaskEntry(
      status: status,
      note: existing?.note,
      updatedAt: DateTime.now(),
    );
    state = state.withEntry(taskId, entry);
    await _repo.saveLog(state);
    _onMutated?.call();
  }

  Future<void> cycleTaskStatus(String taskId) async {
    final current = state.statusFor(taskId);
    await setTaskStatus(taskId, current.next());
  }

  Future<void> setTaskNote(String taskId, String? note) async {
    final cleaned = note?.trim();
    final existing = state.entries[taskId];
    final entry = AwradTaskEntry(
      status: existing?.status ?? AwradStatus.notDone,
      note: (cleaned == null || cleaned.isEmpty) ? null : cleaned,
      updatedAt: DateTime.now(),
    );
    state = state.withEntry(taskId, entry);
    await _repo.saveLog(state);
    _onMutated?.call();
  }
}
