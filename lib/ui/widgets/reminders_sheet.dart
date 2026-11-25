import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../services/notification_service.dart';
import '../../services/settings_provider.dart';
import '../theme/app_theme.dart';

/// Opens a modal bottom sheet to view, add, edit (time + note), toggle, and
/// delete scheduled daily Awrad reminders.
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
    WidgetRef ref, {
    int? index,
    ReminderTime? existing,
  }) async {
    final result = await showDialog<({TimeOfDay time, String note})>(
      context: context,
      builder: (_) => _ReminderEditorDialog(
        initialTime: existing != null
            ? TimeOfDay(hour: existing.hour, minute: existing.minute)
            : const TimeOfDay(hour: 20, minute: 30),
        initialNote: existing?.note ?? '',
        isEditing: existing != null,
      ),
    );
    if (result == null) return;

    final notifier = ref.read(settingsProvider.notifier);
    if (index != null) {
      await notifier.updateReminder(
        index,
        time: result.time,
        note: result.note,
      );
    } else {
      await notifier.addReminder(result.time, note: result.note);
      await NotificationService.instance.requestPermissions();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final reminders = ref.watch(settingsProvider.select((s) => s.reminders));
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
                          'Auto-cancels for today once all Awrad are done',
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
                    onPressed: () => _openEditor(context, ref),
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
                            subtitle: r.note != null && r.note!.isNotEmpty
                                ? Text(
                                    r.note!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.mutedText,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            onTap: () => _openEditor(
                              context,
                              ref,
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
  final TimeOfDay initialTime;
  final String initialNote;
  final bool isEditing;

  const _ReminderEditorDialog({
    required this.initialTime,
    required this.initialNote,
    required this.isEditing,
  });

  @override
  State<_ReminderEditorDialog> createState() => _ReminderEditorDialogState();
}

class _ReminderEditorDialogState extends State<_ReminderEditorDialog> {
  late TimeOfDay _time;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _time = widget.initialTime;
    _noteController = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g., Morning Adhkar or Quran Wird',
            ),
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
            (time: _time, note: _noteController.text),
          ),
          child: Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
