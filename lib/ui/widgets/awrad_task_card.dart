import 'package:flutter/material.dart';

import '../../models/awrad_status.dart';
import '../../models/awrad_task.dart';
import '../theme/app_theme.dart';

/// Tri-state Awrad task card with custom circular toggle, category tag,
/// optional note, half-done amber badge, and optional drag handle.
class AwradTaskCard extends StatelessWidget {
  final AwradTask task;
  final AwradStatus status;
  final String? dailyNote;
  final VoidCallback onToggleStatus;
  final VoidCallback onTap;
  final int? reorderIndex;

  const AwradTaskCard({
    super.key,
    required this.task,
    required this.status,
    this.dailyNote,
    required this.onToggleStatus,
    required this.onTap,
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
          color: isHalf ? colors.amber.withValues(alpha: 0.45) : colors.cardBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight:
                                  isDone ? FontWeight.w500 : FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isDone
                                  ? colors.mutedText
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isHalf) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.amberSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Half done',
                              style: TextStyle(
                                color: colors.amberText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDone
                                ? colors.emeraldSoft
                                : theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDone ? colors.emerald : colors.mutedText,
                            ),
                          ),
                        ),
                        if (effectiveNote != null && effectiveNote.isNotEmpty)
                          Text(
                            effectiveNote,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
                            ),
                          ),
                      ],
                    ),
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
