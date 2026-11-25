import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/awrad_task.dart';
import '../../services/awrad_provider.dart';
import '../../services/notification_service.dart';
import '../../services/settings_provider.dart';
import '../theme/app_theme.dart';

/// Opens a modal bottom sheet to view, add, edit (time + General or specific Wird),
/// toggle, and delete scheduled daily Awrad reminders.
Future<void> showRemindersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _RemindersSheet(),
  );
}

class _RemindersSheet extends ConsumerWidget {
  const _RemindersSheet();

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    List<AwradTask> tasks, {
    int? index,
    ReminderTime? existing,
  }) async {
    final result = await showDialog<({TimeOfDay time, String? taskId})>(
      context: context,
      builder: (_) => _ReminderEditorDialog(
        tasks: tasks,
        initialTime: existing != null
            ? TimeOfDay(hour: existing.hour, minute: existing.minute)
            : const TimeOfDay(hour: 20, minute: 30),
        initialTaskId: existing?.taskId,
        isEditing: existing != null,
      ),
    );
    if (result == null) return;

    final notifier = ref.read(settingsProvider.notifier);
    if (index != null) {
      await notifier.updateReminder(
        index,
        time: result.time,
        taskId: result.taskId,
        clearTaskId: result.taskId == null,
      );
    } else {
      await notifier.addReminder(result.time, taskId: result.taskId);
      await NotificationService.instance.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reminders = ref.watch(settingsProvider.select((s) => s.reminders));
    final tasks = ref.watch(awradTasksProvider);
    final taskTitleById = {for (final t in tasks) t.id: t.title};
    final notifier = ref.read(settingsProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
                          'Scheduled Reminders',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Auto-cancels for today once completed',
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
                    onPressed: () => _openEditor(context, ref, tasks),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: reminders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 44,
                            color: colors.mutedText,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No reminders scheduled yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: reminders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final r = reminders[i];
                        final formatted = TimeOfDay(
                          hour: r.hour,
                          minute: r.minute,
                        ).format(context);
                        final linkedTitle = r.taskId != null
                            ? taskTitleById[r.taskId!]
                            : null;
                        final targetLabel = linkedTitle ?? 'General · All Awrad';

                        return Card(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: Icon(
                              Icons.schedule_rounded,
                              color:
                                  r.enabled ? colors.emerald : colors.mutedText,
                            ),
                            title: Text(
                              formatted,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              targetLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: linkedTitle != null
                                    ? colors.emerald
                                    : colors.mutedText,
                                fontSize: 12,
                                fontWeight: linkedTitle != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            onTap: () => _openEditor(
                              context,
                              ref,
                              tasks,
                              index: i,
                              existing: r,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: r.enabled,
                                  activeThumbColor: colors.emerald,
                                  onChanged: (val) async {
                                    await notifier.toggleReminder(i, val);
                                    if (val) {
                                      await NotificationService.instance
                                          .requestPermissions();
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Delete reminder',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 20,
                                    color: colors.mutedText,
                                  ),
                                  onPressed: () => notifier.removeReminder(i),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ReminderEditorDialog extends StatefulWidget {
  final List<AwradTask> tasks;
  final TimeOfDay initialTime;
  final String? initialTaskId;
  final bool isEditing;

  const _ReminderEditorDialog({
    required this.tasks,
    required this.initialTime,
    required this.initialTaskId,
    required this.isEditing,
  });

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  late TimeOfDay _time;
  String? _selectedTaskId;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    final validIds = widget.tasks.map((t) => t.id).toSet();
    _selectedTaskId =
        validIds.contains(widget.initialTaskId) ? widget.initialTaskId : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Reminder' : 'New Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule_rounded, color: colors.emerald),
            title: const Text('Time'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.emeraldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _time.format(context),
                style: TextStyle(
                  color: colors.emerald,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (picked != null) {
                setState(() => _time = picked);
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedTaskId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Remind for',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('General · All Awrad'),
              ),
              for (final task in widget.tasks)
                DropdownMenuItem<String?>(
                  value: task.id,
                  child: Text(
                    task.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (val) => setState(() => _selectedTaskId = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            (time: _time, taskId: _selectedTaskId),
          ),
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
