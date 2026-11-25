import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_task.dart';
import '../../services/awrad_provider.dart';
import '../theme/app_theme.dart';
import 'awrad_task_sheet.dart';

/// Opens a bottom sheet listing all active Awrad tasks (including weekday-only
/// ones) so users can add, edit, delete, or reorder their full routine in one place.
Future<void> showManageAwradSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _ManageAwradSheet(),
  );
}

class _ManageAwradSheet extends ConsumerWidget {
  const _ManageAwradSheet();

  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _scheduleLabel(AwradTask task) {
    if (task.repeatWeekdays.isEmpty) return 'Every day';
    final sorted = task.repeatWeekdays.toList()..sort();
    return sorted.map((d) => _dayShort[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final tasks = ref.watch(awradTasksProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Awrad',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tasks.length} active · Tap to edit or drag to reorder',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => showAwradTaskSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No Awrad tasks yet.',
                        style: TextStyle(color: colors.mutedText),
                      ),
                    )
                  : CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverReorderableList(
                            itemCount: tasks.length,
                            onReorderItem: (oldIndex, newIndex) {
                              final adjusted =
                                  newIndex > oldIndex ? newIndex + 1 : newIndex;
                              ref
                                  .read(awradTasksProvider.notifier)
                                  .reorderTasks(oldIndex, adjusted);
                            },
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return Padding(
                                key: ValueKey(task.id),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      task.note != null && task.note!.isNotEmpty
                                          ? '${_scheduleLabel(task)} · ${task.note}'
                                          : _scheduleLabel(task),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.mutedText,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () => showAwradTaskSheet(
                                      context,
                                      task: task,
                                    ),
                                    trailing: ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.drag_indicator_rounded,
                                          color: colors.mutedText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
