import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/template_import_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final colors = context.awradColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                secondary: Icon(Icons.screen_lock_portrait_outlined,
                    color: colors.emerald),
                title: const Text('Keep Screen Awake'),
                subtitle: const Text('Prevent dimming during recitation'),
                value: settings.keepScreenAwake,
                activeThumbColor: colors.emerald,
                onChanged: notifier.setKeepScreenAwake,
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.playlist_add, color: colors.emerald),
                title: const Text('Import Awrad Templates'),
                subtitle: const Text('Browse curated daily & Ramadan lists'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showTemplateImportSheet(context),
              ),
              const Divider(),
              ListTile(
                leading:
                    Icon(Icons.notifications_outlined, color: colors.emerald),
                title: const Text('Daily Reminders'),
                subtitle: const Text('Coming in Task 6'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
