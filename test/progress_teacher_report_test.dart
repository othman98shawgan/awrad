import 'package:awrad/main.dart';
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

  test('computeAwradStreak and formatProgressReportText include all Awrad', () {
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

    expect(computeAwradStreak(days, now: today), 3);

    final report = formatProgressReportText(
      periodLabel: 'Nov 22 – Nov 24',
      days: days,
      taskSummaries: taskSummaries,
      streakDays: 3,
    );
    expect(report, contains('Awrad Progress Report — Nov 22 – Nov 24'));
    expect(report, contains('Active days: 3 / 3 | Streak: 3 days'));
    expect(report, contains('Awrad completion: 80%'));
    expect(report, contains('Fard prayers: 13 / 15 (87%)'));
    expect(report, contains('In Masjid: 11 / 15 (73%)'));
    expect(report, contains('Awrad Breakdown:'));
    expect(report, contains('Read Quran: 3 / 3d (100%)'));
    expect(report, contains('Morning adhkar: 2 done, 1 half / 3d (83%)'));
    expect(report.toLowerCase(), isNot(contains('teacher')));
  });

  testWidgets(
      'Progress tab starts month on Sunday and shows Progress Report with all Awrad',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
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
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);

    // Switch to Weekly
    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(find.text('Consistency Heatmap'), findsOneWidget);

    // Open Progress Report sheet
    await tester.scrollUntilVisible(
      find.text('Report'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Progress Report'), findsOneWidget);
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('All Awrad'), findsOneWidget);
    expect(find.text('Read Quran'), findsOneWidget);

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

    expect(find.text('Copy Report'), findsOneWidget);
    await tester.tap(find.text('Copy Report'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copiedText, contains('Awrad Progress Report'));
    expect(copiedText, contains('Read Quran'));
    expect(find.text('Report copied to clipboard.'), findsOneWidget);
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

    await tester.tap(find.text('View Day →'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Progress'), findsOneWidget);
  });
}
