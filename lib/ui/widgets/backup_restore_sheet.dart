import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/awrad_backup.dart';
import '../../services/backup_provider.dart';
import '../theme/app_theme.dart';

String formatBackupTimestamp(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} · $hh:$mm';
}

/// Opens a sheet asking whether to save/share only the Awrad list (for a friend)
/// or a full backup including Awrad and prayer progress (for changing phones).
Future<void> showExportBackupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => const _ExportBackupSheet(),
  );
}

enum _ExportDestination { saveToFiles, share }

class _ExportBackupSheet extends ConsumerStatefulWidget {
  const _ExportBackupSheet();

  @override
  ConsumerState<_ExportBackupSheet> createState() => _ExportBackupSheetState();
}

class _ExportBackupSheetState extends ConsumerState<_ExportBackupSheet> {
  _ExportDestination _destination = _ExportDestination.saveToFiles;
  BackupType? _exportingType;

  Future<void> _export(BackupType type) async {
    if (_exportingType != null) return;
    setState(() => _exportingType = type);

    try {
      final service = ref.read(backupServiceProvider);

      if (_destination == _ExportDestination.saveToFiles) {
        final payload = await service.buildExportPayload(type);
        final savedUri = await FilePicker.saveFile(
          fileName: payload.fileName,
          bytes: payload.bytes,
          mimeType: 'application/json',
          dialogTitle: 'Save Awrad Backup',
        );
        if (!mounted) return;
        if (savedUri == null) {
          setState(() => _exportingType = null);
          return;
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Saved ${payload.fileName}')),
          );
        return;
      }

      final file = await service.writeExportFile(type);
      final subject = type == BackupType.awradOnly
          ? 'Awrad Template'
          : 'Awrad Full Backup';

      if (mounted) {
        Navigator.of(context).pop();
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: subject,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _exportingType = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not export backup: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final isBusy = _exportingType != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save or Share Backup',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save directly to your device Files / Downloads, or share with a friend.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.mutedText,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_ExportDestination>(
              segments: const [
                ButtonSegment(
                  value: _ExportDestination.saveToFiles,
                  icon: Icon(Icons.folder_outlined, size: 18),
                  label: Text('Save to Files'),
                ),
                ButtonSegment(
                  value: _ExportDestination.share,
                  icon: Icon(Icons.ios_share_rounded, size: 18),
                  label: Text('Share'),
                ),
              ],
              selected: {_destination},
              onSelectionChanged: isBusy
                  ? null
                  : (selection) =>
                      setState(() => _destination = selection.first),
            ),
          ),
          const SizedBox(height: 14),
          _ExportOptionCard(
            icon: Icons.playlist_add_check_rounded,
            title: 'Awrad List Only',
            subtitle:
                'Share your routine as a template with a friend (no progress history).',
            isLoading: _exportingType == BackupType.awradOnly,
            enabled: !isBusy,
            onTap: () => _export(BackupType.awradOnly),
          ),
          const SizedBox(height: 10),
          _ExportOptionCard(
            icon: Icons.cloud_download_outlined,
            title: 'Full Backup (Awrad & Progress)',
            subtitle:
                'Save your Awrad list, daily completion history, and prayer logs for moving to a new phone.',
            isLoading: _exportingType == BackupType.fullBackup,
            enabled: !isBusy,
            onTap: () => _export(BackupType.fullBackup),
          ),
        ],
      ),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right_rounded, color: colors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets the user pick a `.json` backup or template file, validates it, and
/// opens a preview sheet to confirm merge vs. replace before importing.
Future<void> pickAndImportBackup(BuildContext context, WidgetRef ref) async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (files.isEmpty) return;

    final picked = files.first;
    final path = picked.path;
    if (path == null) {
      throw const FormatException('Selected file could not be read.');
    }
    final rawJson = await File(path).readAsString();

    final backup = ref.read(backupServiceProvider).parseBackupJson(rawJson);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ImportPreviewSheet(backup: backup),
    );
  } on FormatException catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Invalid backup file: ${e.message}')),
      );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Could not open file: $e')),
      );
  }
}

class _ImportPreviewSheet extends ConsumerStatefulWidget {
  final AwradBackup backup;

  const _ImportPreviewSheet({required this.backup});

  @override
  ConsumerState<_ImportPreviewSheet> createState() =>
      _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends ConsumerState<_ImportPreviewSheet> {
  late BackupImportMode _mode;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.backup.type == BackupType.awradOnly
        ? BackupImportMode.merge
        : BackupImportMode.replace;
  }

  Future<void> _confirmImport() async {
    if (_importing) return;
    setState(() => _importing = true);

    try {
      final service = ref.read(backupServiceProvider);
      await service.importBackup(widget.backup, mode: _mode);
      await refreshAllDataProviders(ref);
      await service.saveAutoBackup();

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.backup.type == BackupType.awradOnly
                  ? 'Imported ${widget.backup.tasks.length} Awrad.'
                  : 'Backup restored successfully.',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final theme = Theme.of(context);
    final isTemplate = widget.backup.type == BackupType.awradOnly;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.emeraldSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTemplate ? 'Awrad Template' : 'Full Backup',
                  style: TextStyle(
                    color: colors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatBackupTimestamp(widget.backup.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ready to Import',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.checklist_rounded,
                label: '${widget.backup.tasks.length} Awrad',
              ),
              if (!isTemplate) ...[
                _SummaryChip(
                  icon: Icons.calendar_today_rounded,
                  label: '${widget.backup.awradLogs.length} Awrad days',
                ),
                _SummaryChip(
                  icon: Icons.mosque_outlined,
                  label: '${widget.backup.prayerLogs.length} Prayer days',
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Import Mode',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<BackupImportMode>(
              segments: [
                ButtonSegment(
                  value: BackupImportMode.merge,
                  label: Text(isTemplate ? 'Add to List' : 'Merge'),
                ),
                ButtonSegment(
                  value: BackupImportMode.replace,
                  label: Text(isTemplate ? 'Replace List' : 'Replace All'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _importing
                  ? null
                  : (selection) => setState(() => _mode = selection.first),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _modeDescription(isTemplate, _mode),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.mutedText,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _importing ? null : _confirmImport,
              child: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isTemplate ? 'Import Awrad' : 'Restore Backup',
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _modeDescription(bool isTemplate, BackupImportMode mode) {
    if (isTemplate) {
      return mode == BackupImportMode.merge
          ? 'Adds new Awrad from this template and skips duplicates by title. Your existing progress stays untouched.'
          : 'Replaces your current Awrad list with this template. Your historical progress logs are kept.';
    }
    return mode == BackupImportMode.replace
        ? 'Replaces all current Awrad and progress with this backup. Best when setting up a new phone.'
        : 'Keeps your existing Awrad and progress while adding missing items and newer entries.';
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.emeraldSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.emerald),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prompts the user on startup when local storage is empty and an automatic
/// backup file is found on disk.
Future<void> showStartupRecoveryDialog(
  BuildContext context,
  WidgetRef ref,
  AwradBackup backup,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final colors = dialogContext.awradColors;
      return AlertDialog(
        icon: Icon(Icons.restore_rounded, color: colors.emerald, size: 32),
        title: const Text('Backup Found'),
        content: Text(
          'We found a local backup from ${formatBackupTimestamp(backup.createdAt)} '
          '(${backup.tasks.length} Awrad, ${backup.awradLogs.length} Awrad days, '
          '${backup.prayerLogs.length} prayer days).\n\n'
          'Would you like to restore your previous data?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final service = ref.read(backupServiceProvider);
              await service.importBackup(
                backup,
                mode: BackupImportMode.replace,
              );
              await refreshAllDataProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Previous Awrad & progress restored.'),
                    ),
                  );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      );
    },
  );
}

/// Shows details about the local auto-backup with options to back up now or
/// restore from the saved snapshot.
Future<void> showAutoBackupDialog(
  BuildContext context,
  WidgetRef ref,
  AutoBackupInfo? info,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.awradColors;
      return AlertDialog(
        icon: Icon(Icons.save_outlined, color: colors.emerald, size: 30),
        title: const Text('Local Auto-Backup'),
        content: Text(
          info == null
              ? 'No automatic backup file has been saved yet. Awrad saves one automatically whenever you track your habits.'
              : 'Last saved: ${formatBackupTimestamp(info.createdAt)}\n'
                  'Contains ${info.taskCount} Awrad, ${info.awradLogDays} Awrad days, and ${info.prayerLogDays} prayer days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          if (info != null)
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final service = ref.read(backupServiceProvider);
                final backup = await service.loadAutoBackup();
                if (backup == null) return;
                await service.importBackup(
                  backup,
                  mode: BackupImportMode.replace,
                );
                await refreshAllDataProviders(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Restored from local auto-backup.'),
                      ),
                    );
                }
              },
              child: const Text('Restore'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(backupServiceProvider).saveAutoBackup();
              ref.invalidate(autoBackupInfoProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(
                      content: Text('Local auto-backup updated.'),
                    ),
                  );
              }
            },
            child: const Text('Back Up Now'),
          ),
        ],
      );
    },
  );
}
