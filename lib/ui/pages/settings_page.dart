import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/settings_provider.dart';
import '../../services/awrad_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/manage_awrad_sheet.dart';
import '../widgets/prayer_sunnah_sheet.dart';
import '../widgets/template_import_sheet.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  int _versionTapCount = 0;

  void _handleVersionTap(bool currentlyEnabled) {
    if (currentlyEnabled) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Developer mode is already enabled.')),
        );
      return;
    }

    _versionTapCount++;
    final remaining = 7 - _versionTapCount;
    if (remaining <= 0) {
      _versionTapCount = 0;
      ref.read(settingsProvider.notifier).setDeveloperMode(true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Developer mode enabled!')),
        );
    } else if (_versionTapCount >= 3) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 1),
            content: Text(
              'Tap $remaining more ${remaining == 1 ? 'time' : 'times'} for Developer Mode',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final taskCount = ref.watch(awradTasksProvider).length;
    final colors = context.awradColors;
    final theme = Theme.of(context);

    final reminderTime = TimeOfDay(
      hour: settings.reminderHour,
      minute: settings.reminderMinute,
    );
    final formattedReminderTime = reminderTime.format(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.emeraldSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colors.emerald,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Guest Mode',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.emeraldSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: colors.emerald,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saved on this device · Cloud sync & accounts coming soon',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'AWRAD & PRAYERS'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.playlist_add, color: colors.emerald),
                title: const Text('Import Awrad Templates'),
                subtitle: const Text('Browse curated daily & Ramadan lists'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showTemplateImportSheet(context),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.checklist_rounded, color: colors.emerald),
                title: const Text('Manage Awrad Tasks'),
                subtitle: Text('$taskCount active · Edit, delete, or reorder'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showManageAwradSheet(context),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.tune_rounded, color: colors.emerald),
                title: const Text('Customize Sunnah Prayers'),
                subtitle: const Text('Mu’akkadah & Mustahabbah rak‘ahs'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showPrayerSunnahSheet(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionHeader(title: 'PREFERENCES'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: colors.emerald),
                    const SizedBox(width: 12),
                    Text(
                      'Theme Appearance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined, size: 18),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined, size: 18),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined, size: 18),
                        label: Text('System'),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) {
                      notifier.setThemeMode(selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary:
                    Icon(Icons.notifications_outlined, color: colors.emerald),
                title: const Text('Daily Reminder'),
                subtitle: Text(
                  settings.dailyReminderEnabled
                      ? 'Saved for $formattedReminderTime (OS notifications coming soon)'
                      : 'Off · Tap to save a reminder time',
                ),
                value: settings.dailyReminderEnabled,
                activeThumbColor: colors.emerald,
                onChanged: (enabled) =>
                    notifier.setDailyReminder(enabled: enabled),
              ),
              if (settings.dailyReminderEnabled) ...[
                const Divider(),
                ListTile(
                  leading:
                      Icon(Icons.schedule_rounded, color: colors.emerald),
                  title: const Text('Reminder Time'),
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
                      formattedReminderTime,
                      style: TextStyle(
                        color: colors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminderTime,
                    );
                    if (picked != null) {
                      await notifier.setDailyReminder(
                        hour: picked.hour,
                        minute: picked.minute,
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        if (settings.developerModeEnabled) ...[
          const SizedBox(height: 18),
          const _SectionHeader(title: 'DEVELOPER'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.screen_lock_portrait_outlined,
                    color: colors.emerald,
                  ),
                  title: const Text('Keep Screen Awake'),
                  subtitle: const Text('Prevent dimming during recitation'),
                  value: settings.keepScreenAwake,
                  activeThumbColor: colors.emerald,
                  onChanged: notifier.setKeepScreenAwake,
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.code_off_rounded, color: colors.mutedText),
                  title: const Text('Hide Developer Mode'),
                  onTap: () {
                    setState(() => _versionTapCount = 0);
                    notifier.setDeveloperMode(false);
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _handleVersionTap(settings.developerModeEnabled),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                'Awrad v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.mutedText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.emerald,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
