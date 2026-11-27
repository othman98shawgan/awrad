import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models/awrad_status.dart';
import 'services/awrad_provider.dart';
import 'services/backup_provider.dart';
import 'services/date_utils.dart';
import 'services/notification_service.dart';
import 'services/prayer_provider.dart';
import 'services/progress_provider.dart';
import 'services/selected_date_provider.dart';
import 'services/settings_provider.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/prayer_progress_page.dart';
import 'ui/pages/progress_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/awrad_task_sheet.dart';
import 'ui/widgets/backup_restore_sheet.dart';
import 'ui/widgets/date_switcher_bar.dart';
import 'ui/widgets/prayer_sunnah_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ProviderScope(child: OradApp()));
}

class OradApp extends ConsumerStatefulWidget {
  const OradApp({super.key});

  @override
  ConsumerState<OradApp> createState() => _OradAppState();
}

class _OradAppState extends ConsumerState<OradApp> with WidgetsBindingObserver {
  late DateTime _lastActiveDay;

  @override
  void initState() {
    super.initState();
    _lastActiveDay = normalizeDate(DateTime.now());
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService.instance.init();
    await NotificationService.instance.requestPermissions();
    if (mounted) {
      _syncReminder();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      ref.read(backupServiceProvider).flushAutoBackup();
    }
    if (state == AppLifecycleState.resumed) {
      final nowDay = normalizeDate(DateTime.now());
      if (nowDay != _lastActiveDay) {
        final prevDay = _lastActiveDay;
        _lastActiveDay = nowDay;
        if (ref.read(selectedDateProvider) == prevDay) {
          ref.read(selectedDateProvider.notifier).selectDate(nowDay);
        }
      }
      _syncReminder();
    }
  }

  void _syncReminder() {
    final today = normalizeDate(DateTime.now());
    final settings = ref.read(settingsProvider);
    final allTasks = ref.read(awradTasksProvider);
    final tasksToday = allTasks.where((t) => t.appliesTo(today)).toList();
    final log = ref.read(dailyAwradLogProvider(today));
    final remaining = tasksToday
        .where((t) => log.statusFor(t.id) != AwradStatus.done)
        .length;
    final titlesById = {for (final t in allTasks) t.id: t.title};
    final doneIds = tasksToday
        .where((t) => log.statusFor(t.id) == AwradStatus.done)
        .map((t) => t.id)
        .toSet();
    NotificationService.instance.syncReminders(
      reminders: settings.reminders,
      remainingAwradCount: remaining,
      taskTitlesById: titlesById,
      doneTaskIds: doneIds,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final today = normalizeDate(DateTime.now());

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

    ref.listen(settingsProvider, (_, __) => _syncReminder());
    ref.listen(awradTasksProvider, (_, __) {
      _syncReminder();
      ref.read(backupServiceProvider).scheduleAutoBackup();
    });
    ref.listen(dailyAwradLogProvider(today), (_, __) => _syncReminder());
    ref.listen(awradDataVersionProvider, (_, __) {
      ref.read(backupServiceProvider).scheduleAutoBackup();
    });
    ref.listen(prayerDataVersionProvider, (_, __) {
      ref.read(backupServiceProvider).scheduleAutoBackup();
    });

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStartupRecovery());
  }

  Future<void> _checkStartupRecovery() async {
    await ref.read(awradTasksProvider.notifier).load();
    final backup = await ref.read(backupServiceProvider).checkStartupRecovery();
    if (backup != null && mounted) {
      await showStartupRecoveryDialog(context, ref, backup);
    }
  }

  static const _titles = [
    'Awrad',
    'Daily Prayers',
    'Progress',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.awradColors;
    final showTodayAction = _currentIndex == 0 || _currentIndex == 1;
    final progressAnchor = ref.watch(progressAnchorDateProvider);
    final today = normalizeDate(DateTime.now());
    final todaySundayStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday % 7),
    );
    final anchorSundayStart = DateTime(
      progressAnchor.year,
      progressAnchor.month,
      progressAnchor.day - (progressAnchor.weekday % 7),
    );
    final isCurrentWeek = anchorSundayStart == todaySundayStart;
    final pages = [
      HomePage(isActive: _currentIndex == 0),
      PrayerProgressPage(isActive: _currentIndex == 1),
      ProgressPage(onJumpToAwrad: () => setState(() => _currentIndex = 0)),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (showTodayAction) const TodayCalendarButton(),
          if (_currentIndex == 2) ...[
            if (ref.watch(progressIsMonthlyProvider))
              IconButton(
                tooltip: ref.watch(progressHijriCalendarProvider)
                    ? 'Switch to Gregorian month'
                    : 'Switch to Hijri month',
                icon: Icon(
                  ref.watch(progressHijriCalendarProvider)
                      ? Icons.nights_stay_rounded
                      : Icons.nights_stay_outlined,
                  color: ref.watch(progressHijriCalendarProvider)
                      ? colors.emerald
                      : null,
                ),
                onPressed: () {
                  final notifier =
                      ref.read(progressHijriCalendarProvider.notifier);
                  notifier.state = !notifier.state;
                },
              ),
            TodayCalendarButton(
              tooltip: 'This week',
              isCurrentOverride: isCurrentWeek,
              onPressedOverride: () =>
                  ref.read(progressAnchorDateProvider.notifier).state = today,
            ),
          ],
          if (_currentIndex == 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => showAwradTaskSheet(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'New Wird',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            )
          else if (_currentIndex == 1)
            IconButton(
              tooltip: 'Customize Sunnah',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => showPrayerSunnahSheet(context),
            )
          else
            const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
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
