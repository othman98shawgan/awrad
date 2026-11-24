import 'package:flutter/material.dart';

import '../../models/awrad_status.dart';
import '../../models/awrad_task.dart';
import '../theme/app_theme.dart';

/// Tri-state Awrad task card with custom circular toggle, category tag,
/// optional note, and optional drag handle.
/// Tap toggles completion status; long press opens the edit sheet.
class AwradTaskCard extends StatelessWidget {
  final AwradTask task;
  final AwradStatus status;
  final String? dailyNote;
  final VoidCallback onToggleStatus;
  final VoidCallback onLongPress;
  final int? reorderIndex;

  const AwradTaskCard({
    super.key,
    required this.task,
    required this.status,
    this.dailyNote,
    required this.onToggleStatus,
    required this.onLongPress,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final isDone = status == AwradStatus.done;
    final isHalf = status == AwradStatus.halfDone;
    final effectiveNote = (dailyNote != null && dailyNote!.isNotEmpty)
        ? dailyNote
        : task.note;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isHalf ? colors.amber.withValues(alpha: 0.45) : colors.cardBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleStatus,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _TriStateToggle(
                status: status,
                onTap: onToggleStatus,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                        color: isDone
                            ? colors.mutedText
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (effectiveNote != null && effectiveNote.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        effectiveNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (reorderIndex != null) ...[
                const SizedBox(width: 4),
                ReorderableDragStartListener(
                  index: reorderIndex!,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      size: 20,
                      color: colors.mutedText.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TriStateToggle extends StatelessWidget {
  final AwradStatus status;
  final VoidCallback onTap;

  const _TriStateToggle({
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final isDone = status == AwradStatus.done;
    final isHalf = status == AwradStatus.halfDone;

    return Semantics(
      button: true,
      label: 'Toggle task status',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone
                  ? colors.emerald
                  : isHalf
                      ? colors.amberSoft
                      : Colors.transparent,
              border: Border.all(
                color: isDone
                    ? colors.emerald
                    : isHalf
                        ? colors.amber
                        : colors.cardBorder,
                width: 2,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : isHalf
                    ? Icon(Icons.remove_rounded, size: 16, color: colors.amber)
                    : null,
          ),
        ),
      ),
    );
  }
}
