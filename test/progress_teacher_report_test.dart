import 'package:awrad/main.dart';
import 'package:awrad/models/awrad_status.dart';
import 'package:awrad/models/awrad_task.dart';
import 'package:awrad/services/date_utils.dart';
import 'package:awrad/services/progress_provider.dart';
import 'package:awrad/ui/widgets/teacher_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('formatAwradReportText and formatPrayersReportText format separate reports',
      () {
    final today = DateTime(2026, 11, 24);
    final days = [
      DailyProgressSummary(
        date: DateTime(2026, 11, 22),
        awradTotal: 10,
        awradDone: 8,
        awradHalfDone: 0,
        awradScore: 0.8,
        prayersDone: 5,
        prayersHalfDone: 0,
        prayersInMasjid: 4,
        completedRakahs: 30,
        totalRakahs: 32,
      ),
      DailyProgressSummary(
        date: DateTime(2026, 11, 23),
        awradTotal: 10,
        awradDone: 10,
        awradHalfDone: 0,
        awradScore: 1.0,
        prayersDone: 5,
        prayersHalfDone: 0,
        prayersInMasjid: 5,
        completedRakahs: 32,
        totalRakahs: 32,
      ),
      DailyProgressSummary(
        date: today,
        awradTotal: 10,
        awradDone: 5,
        awradHalfDone: 2,
        awradScore: 0.6,
        prayersDone: 3,
        prayersHalfDone: 0,
        prayersInMasjid: 2,
        completedRakahs: 20,
        totalRakahs: 32,
      ),
    ];

    const taskSummaries = [
      AwradTaskSummary(
        taskId: '1',
        title: 'Read Quran',
        applicableDays: 3,
        doneDays: 3,
        halfDays: 0,
      ),
      AwradTaskSummary(
        taskId: '2',
        title: 'Morning adhkar',
        applicableDays: 3,
        doneDays: 2,
        halfDays: 1,
      ),
    ];

    const prayerSummaries = [
      PrayerPeriodSummary(
        name: 'Fajr',
        daysCount: 3,
        fardDoneCount: 3,
        inMasjidCount: 2,
        completedRakahs: 10,
        totalRakahs: 12,
      ),
    ];

    expect(computeAwradStreak(days, now: today), 3);

    final awradReport = formatAwradReportText(
      periodLabel: 'Nov 22 – Nov 24',
      elapsedDays: days,
      taskSummaries: taskSummaries,
      streakDays: 3,
    );
    expect(awradReport, contains('Awrad Report — Nov 22 – Nov 24'));
    expect(awradReport, contains('Active days: 3 / 3 | Streak: 3 days'));
    expect(awradReport, contains('Overall completion: 80%'));
    expect(awradReport, contains('Read Quran: 3 / 3d (100%)'));
    expect(awradReport, contains('Morning adhkar: 2 done, 1 half / 3d (83%)'));
    expect(awradReport, isNot(contains('Fard prayers')));

    final prayersReport = formatPrayersReportText(
      periodLabel: 'Nov 22 – Nov 24',
      elapsedDays: days,
      prayerSummaries: prayerSummaries,
    );
    expect(prayersReport, contains('Prayers Report — Nov 22 – Nov 24'));
    expect(prayersReport, contains('Fard prayers: 13 / 15 (87%)'));
    expect(prayersReport, contains('In Masjid: 11 / 15 (73%)'));
    expect(prayersReport, contains('Fajr: 3/3 Fard · 2 Masjid · 10/12 rak‘ahs'));
  });

  testWidgets(
      'Progress tab starts week on Sunday, counts elapsed days, and opens Awrad & Prayers reports',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    // Import Daily Essentials so the Awrad Report has tasks to display
    await tester.tap(find.text('Tap here to choose from templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Essentials'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Consistency Heatmap'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    // Switch Monthly view to Hijri calendar and verify Hijri month header
    expect(find.byTooltip('Switch to Hijri month'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to Hijri month'));
    await tester.pumpAndSettle();
    final todayHijri = toHijriDate(DateTime.now());
    expect(
      find.text('${todayHijri.monthName} ${todayHijri.year} AH'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Switch to Gregorian month'));
    await tester.pumpAndSettle();

    // Switch to Weekly and verify Sunday is still the first day label
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(find.text('Sun'), findsOneWidget);

    // Step to previous week and return via AppBar 'This week' icon
    await tester.tap(find.byTooltip('Previous period'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('This week'));
    await tester.pumpAndSettle();

    // Scroll to Reports cards
    final verticalScrollable = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.scrollUntilVisible(
      find.text('Prayers Report'),
      200,
      scrollable: verticalScrollable,
    );
    await tester.ensureVisible(find.text('Prayers Report'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Elapsed days in'), findsNWidgets(2));
    expect(find.text('Awrad Report'), findsOneWidget);
    expect(find.text('Prayers Report'), findsOneWidget);

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    // Open Awrad Report (first 'Report' button) and copy
    await tester.tap(find.text('Report').first);
    await tester.pumpAndSettle();
    expect(find.text('All Awrad'), findsOneWidget);
    expect(find.text('Quran'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('Copy Awrad Report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(copiedText, contains('Awrad Report —'));

    // Open Prayers Report (second 'Report' button)
    await tester.tap(find.text('Report').last);
    await tester.pumpAndSettle();
    expect(find.text('By Prayer'), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);
  });

  testWidgets('tapping View Day jumps to Awrad tab', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View Day →'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View Day →'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Progress'), findsOneWidget);
  });

  test('computeWirdStreak and computeBestWirdStreak skip non-applicable days',
      () {
    // Daily task with grace period on today and halfDone keeping streak alive.
    final today = DateTime(2026, 11, 28);
    final dailyDays = [
      WirdDayProgress(
        date: DateTime(2026, 11, 24),
        isApplicable: true,
        status: AwradStatus.notDone,
      ),
      WirdDayProgress(
        date: DateTime(2026, 11, 25),
        isApplicable: true,
        status: AwradStatus.done,
      ),
      WirdDayProgress(
        date: DateTime(2026, 11, 26),
        isApplicable: true,
        status: AwradStatus.halfDone,
      ),
      WirdDayProgress(
        date: DateTime(2026, 11, 27),
        isApplicable: true,
        status: AwradStatus.done,
      ),
      WirdDayProgress(
        date: today,
        isApplicable: true,
        status: AwradStatus.notDone,
      ),
    ];
    expect(computeWirdStreak(dailyDays, now: today), 3);
    expect(computeBestWirdStreak(dailyDays), 3);

    // Friday-only task: completing 3 consecutive Fridays = streak 3 despite off-days.
    final fridayTaskDays = <WirdDayProgress>[];
    for (final date in datesInRange(DateTime(2026, 11, 1), today)) {
      final isFri = date.weekday == DateTime.friday;
      // Nov 6 (missed), Nov 13 (done), Nov 20 (done), Nov 27 (done)
      final status = isFri && date.day >= 13
          ? AwradStatus.done
          : AwradStatus.notDone;
      fridayTaskDays.add(
        WirdDayProgress(
          date: date,
          isApplicable: isFri,
          status: status,
        ),
      );
    }
    expect(computeWirdStreak(fridayTaskDays, now: today), 3);
    expect(computeBestWirdStreak(fridayTaskDays), 3);
  });

  test('formatWirdReportText formats completion stats and daily notes', () {
    final now = DateTime(2026, 11, 28);
    final task = AwradTask(
      id: 'q1',
      title: 'Read Quran',
      createdAt: now,
      updatedAt: now,
    );
    final days = [
      WirdDayProgress(
        date: DateTime(2026, 11, 26),
        isApplicable: true,
        status: AwradStatus.done,
        note: 'Juz 2 complete',
      ),
      WirdDayProgress(
        date: DateTime(2026, 11, 27),
        isApplicable: true,
        status: AwradStatus.halfDone,
      ),
      WirdDayProgress(
        date: DateTime(2026, 11, 28),
        isApplicable: true,
        status: AwradStatus.notDone,
      ),
    ];

    final text = formatWirdReportText(
      task: task,
      periodLabel: 'Nov 26 – Nov 28',
      elapsedDays: days,
      streakDays: 2,
    );
    expect(text, contains('Wird Report: Read Quran — Nov 26 – Nov 28'));
    expect(text, contains('Scheduled days: 3 | Streak: 2 days'));
    expect(text, contains('Completion: 50% (1 done, 1 half, 1 missed)'));
    expect(text, contains('Notes:'));
    expect(text, contains('Juz 2 complete'));
  });

  testWidgets(
      'Progress tab filters by a single Wird, shows dedicated stats, and opens Wird Report',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    // Import Daily Essentials so we have active Awrad to filter.
    await tester.tap(find.text('Tap here to choose from templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daily Essentials'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Navigate to Progress tab
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Progress'),
      ),
    );
    await tester.pumpAndSettle();

    // Filter bar is visible with 'All' and 'Quran'
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Quran'), findsOneWidget);

    // Select 'Quran' filter
    await tester.tap(find.text('Quran'));
    await tester.pumpAndSettle();

    // Single-Wird legend appears; overall 'In Masjid' & 'Prayers Report' hide
    expect(find.text('Missed'), findsOneWidget);
    expect(find.text('Half'), findsOneWidget);
    expect(find.text('Done'), findsAtLeastNWidgets(1));
    expect(find.text('In Masjid'), findsNothing);
    expect(find.text('Prayers Report'), findsNothing);

    // Scroll to single-Wird inline report card
    final verticalScrollable = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last;
    await tester.scrollUntilVisible(
      find.text('Copy Report'),
      200,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Completion'), findsOneWidget);
    expect(find.text('Quran Report'), findsOneWidget);
    expect(find.text('Copy Report'), findsOneWidget);

    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.tap(find.text('Copy Report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(copiedText, contains('Wird Report: Quran —'));

    // Switch back to 'All' and verify overall view returns
    await tester.scrollUntilVisible(
      find.text('All'),
      -200,
      scrollable: verticalScrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('In Masjid'), findsOneWidget);
  });
}
