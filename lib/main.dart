import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'services/settings_provider.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/prayer_progress_page.dart';
import 'ui/pages/progress_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/date_switcher_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: OradApp()));
}

class OradApp extends ConsumerWidget {
  const OradApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ref.listen<bool>(
      settingsProvider.select((s) => s.keepScreenAwake),
      (_, enabled) {
        if (enabled) {
          WakelockPlus.enable();
        } else {
          WakelockPlus.disable();
        }
      },
    );

    return MaterialApp(
      title: 'Awrad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const AwradShell(),
    );
  }
}

/// Unified 4-tab application shell with a single AppBar and Material 3 NavigationBar.
class AwradShell extends ConsumerStatefulWidget {
  const AwradShell({super.key});

  @override
  ConsumerState<AwradShell> createState() => _AwradShellState();
}

class _AwradShellState extends ConsumerState<AwradShell> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    PrayerProgressPage(),
    ProgressPage(),
    SettingsPage(),
  ];

  static const _titles = [
    'Awrad',
    'Daily Prayers',
    'Progress',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final showCalendarAction = _currentIndex == 0 || _currentIndex == 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (showCalendarAction)
            IconButton(
              tooltip: 'Pick date',
              icon: const Icon(Icons.calendar_month_rounded),
              onPressed: () =>
                  DateSwitcherBar.openCalendarPicker(context, ref),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.cardBorder)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              selectedIcon: Icon(Icons.checklist_rounded),
              label: 'Awrad',
            ),
            NavigationDestination(
              icon: Icon(Icons.mosque_outlined),
              selectedIcon: Icon(Icons.mosque_rounded),
              label: 'Prayer',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
