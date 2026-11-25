import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../models/awrad_task.dart';
import '../../services/awrad_provider.dart';
import '../../services/notification_service.dart';
import '../../services/settings_provider.dart';
import '../theme/app_theme.dart';

/// Opens a modal bottom sheet to view, add, edit, toggle, and delete
/// scheduled daily Awrad reminders inline without stacking modals.
Future<void> showRemindersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _RemindersSheet(),
  );
}

class _RemindersSheet extends ConsumerStatefulWidget {
  const _RemindersSheet();

  @override
  ConsumerState<_RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends ConsumerState<_RemindersSheet> {
  bool _isEditingMode = false;
  int? _editingIndex;
  TimeOfDay _draftTime = const TimeOfDay(hour: 20, minute: 30);
  String? _draftTaskId;

  void _openAdd() {
    setState(() {
      _isEditingMode = true;
      _editingIndex = null;
      _draftTime = const TimeOfDay(hour: 20, minute: 30);
      _draftTaskId = null;
    });
  }

  void _openEdit(int index, ReminderTime existing, List<AwradTask> tasks) {
    final validIds = tasks.map((t) => t.id).toSet();
    setState(() {
      _isEditingMode = true;
      _editingIndex = index;
      _draftTime = TimeOfDay(hour: existing.hour, minute: existing.minute);
      _draftTaskId =
          validIds.contains(existing.taskId) ? existing.taskId : null;
    });
  }

  void _closeEditor() {
    setState(() {
      _isEditingMode = false;
      _editingIndex = null;
    });
  }

  Future<void> _saveEditor() async {
    final notifier = ref.read(settingsProvider.notifier);
    if (_editingIndex != null) {
      await notifier.updateReminder(
        _editingIndex!,
        time: _draftTime,
        taskId: _draftTaskId,
        clearTaskId: _draftTaskId == null,
      );
    } else {
      await notifier.addReminder(_draftTime, taskId: _draftTaskId);
      if (mounted) _closeEditor();
      await NotificationService.instance.requestPermissions();
      return;
    }
    if (mounted) _closeEditor();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reminders = ref.watch(settingsProvider.select((s) => s.reminders));
    final tasks = ref.watch(awradTasksProvider);
    final taskTitleById = {for (final t in tasks) t.id: t.title};

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      minChildSize: 0.42,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isEditingMode
              ? _buildEditor(context, colors, theme, tasks, scrollController)
              : _buildList(
                  context,
                  colors,
                  theme,
                  reminders,
                  tasks,
                  taskTitleById,
                  scrollController,
                ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    AwradColors colors,
    ThemeData theme,
    List<ReminderTime> reminders,
    List<AwradTask> tasks,
    Map<String, String> taskTitleById,
    ScrollController scrollController,
  ) {
    final notifier = ref.read(settingsProvider.notifier);

    return Column(
      key: const ValueKey('reminders_list'),
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
                onPressed: _openAdd,
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
                    final linkedTitle =
                        r.taskId != null ? taskTitleById[r.taskId!] : null;
                    final targetLabel = linkedTitle ?? 'General · All Awrad';

                    return Card(
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        leading: Icon(
                          Icons.schedule_rounded,
                          color: r.enabled ? colors.emerald : colors.mutedText,
                        ),
                        title: Text(
                          formatted,
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
                        onTap: () => _openEdit(i, r, tasks),
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
  }

  Widget _buildEditor(
    BuildContext context,
    AwradColors colors,
    ThemeData theme,
    List<AwradTask> tasks,
    ScrollController scrollController,
  ) {
    final isEdit = _editingIndex != null;
    return Column(
      key: const ValueKey('reminders_editor'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _closeEditor,
              ),
              Text(
                isEdit ? 'Edit Reminder' : 'New Reminder',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Card(
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(Icons.schedule_rounded, color: colors.emerald),
                  title: const Text('Time'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.emeraldSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _draftTime.format(context),
                      style: TextStyle(
                        color: colors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _draftTime,
                    );
                    if (picked != null) {
                      setState(() => _draftTime = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: _draftTaskId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Remind for',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('General · All Awrad'),
                  ),
                  for (final task in tasks)
                    DropdownMenuItem<String?>(
                      value: task.id,
                      child: Text(
                        task.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (val) => setState(() => _draftTaskId = val),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saveEditor,
              child: Text(isEdit ? 'Save Reminder' : 'Add Reminder'),
            ),
          ),
        ),
      ],
    );
  }
}
