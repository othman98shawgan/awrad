import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/awrad_task.dart';
import '../../services/awrad_provider.dart';
import '../theme/app_theme.dart';

/// Opens a modal bottom sheet to create a new [AwradTask] or edit/delete an existing one.
Future<void> showAwradTaskSheet(
  BuildContext context, {
  AwradTask? task,
  DateTime? forDate,
  String? dailyNote,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AwradTaskSheet(
      task: task,
      forDate: forDate,
      dailyNote: dailyNote,
    ),
  );
}

class _AwradTaskSheet extends ConsumerStatefulWidget {
  final AwradTask? task;
  final DateTime? forDate;
  final String? dailyNote;

  const _AwradTaskSheet({
    this.task,
    this.forDate,
    this.dailyNote,
  });

  @override
  ConsumerState<_AwradTaskSheet> createState() => _AwradTaskSheetState();
}

class _AwradTaskSheetState extends ConsumerState<_AwradTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _dailyNoteController;

  late AwradCategory _category;
  late bool _everyDay;
  late Set<int> _selectedWeekdays;

  static const _weekdayLabels = [
    (DateTime.monday, 'Mon'),
    (DateTime.tuesday, 'Tue'),
    (DateTime.wednesday, 'Wed'),
    (DateTime.thursday, 'Thu'),
    (DateTime.friday, 'Fri'),
    (DateTime.saturday, 'Sat'),
    (DateTime.sunday, 'Sun'),
  ];

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleController = TextEditingController(text: t?.title ?? '');
    _noteController = TextEditingController(text: t?.note ?? '');
    _dailyNoteController = TextEditingController(text: widget.dailyNote ?? '');
    _category = t?.category ?? AwradCategory.other;
    _selectedWeekdays = Set<int>.from(t?.repeatWeekdays ?? const {});
    _everyDay = _selectedWeekdays.isEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _dailyNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final weekdays = _everyDay ? const <int>{} : _selectedWeekdays;
    final notifier = ref.read(awradTasksProvider.notifier);

    if (_isEditing) {
      final cleanedNote = _noteController.text.trim();
      await notifier.updateTask(
        widget.task!.copyWith(
          title: _titleController.text.trim(),
          category: _category,
          repeatWeekdays: weekdays,
          note: cleanedNote.isEmpty ? null : cleanedNote,
          clearNote: cleanedNote.isEmpty,
        ),
      );
      if (widget.forDate != null) {
        await ref
            .read(dailyAwradLogProvider(widget.forDate!).notifier)
            .setTaskNote(widget.task!.id, _dailyNoteController.text);
      }
    } else {
      await notifier.addTask(
        title: _titleController.text.trim(),
        category: _category,
        repeatWeekdays: weekdays,
        note: _noteController.text.trim(),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Wird?'),
        content: Text(
          'Remove "${widget.task!.title}" from your Awrad list? Past completion history will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(awradTasksProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Wird' : 'New Wird',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Read 1 Juz of Quran',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repeat every day',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _everyDay,
                    activeThumbColor: colors.emerald,
                    onChanged: (v) {
                      setState(() {
                        _everyDay = v;
                        if (!v && _selectedWeekdays.isEmpty) {
                          _selectedWeekdays = {
                            DateTime.monday,
                            DateTime.thursday,
                          };
                        }
                      });
                    },
                  ),
                ],
              ),
              if (!_everyDay) ...[
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < _weekdayLabels.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        FilterChip(
                          showCheckmark: false,
                          label: Text(_weekdayLabels[i].$2),
                          selected:
                              _selectedWeekdays.contains(_weekdayLabels[i].$1),
                          selectedColor: colors.emerald,
                          labelStyle: TextStyle(
                            color: _selectedWeekdays
                                    .contains(_weekdayLabels[i].$1)
                                ? Colors.white
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (isOn) {
                            final day = _weekdayLabels[i].$1;
                            setState(() {
                              if (isOn) {
                                _selectedWeekdays.add(day);
                              } else if (_selectedWeekdays.length > 1) {
                                _selectedWeekdays.remove(day);
                              }
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Default note (optional)',
                  hintText: 'e.g., After Fajr prayer',
                ),
              ),
              if (_isEditing && widget.forDate != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _dailyNoteController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note for this day (optional)',
                    hintText: 'e.g., Completed 100 of 200 so far',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_isEditing) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: Text(_isEditing ? 'Save Changes' : 'Add Wird'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
