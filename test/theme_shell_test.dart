import 'package:awrad/main.dart';
import 'package:awrad/services/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders unified 4-tab shell with a single AppBar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(find.byType(AppBar), findsOneWidget);
    expect(navBar, findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Awrad')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Prayer')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Progress')),
        findsOneWidget);
    expect(find.descendant(of: navBar, matching: find.text('Settings')),
        findsOneWidget);

    // Switch to Prayer tab and verify still a single AppBar.
    await tester.tap(find.descendant(of: navBar, matching: find.text('Prayer')));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Daily Prayers'), findsOneWidget);
  });

  testWidgets('toggling Dark theme in Settings updates MaterialApp themeMode',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_settings_v1'), contains('"themeMode":"dark"'));
  });

  testWidgets('DateSwitcherBar steps dates and TodayCalendarButton returns to today',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    final today = normalizeDate(DateTime.now());
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    expect(find.text(formatFriendlyDate(today, now: today)), findsOneWidget);
    expect(find.text(formatHijriDate(today)), findsOneWidget);
    expect(find.byTooltip('Go to today'), findsOneWidget);
    expect(find.text('${today.day}'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous day').first);
    await tester.pumpAndSettle();

    expect(
      find.text(formatFriendlyDate(yesterday, now: today)),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Go to today'));
    await tester.pumpAndSettle();

    expect(find.text(formatFriendlyDate(today, now: today)), findsOneWidget);
  });
}
