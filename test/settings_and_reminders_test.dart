import 'package:awrad/main.dart';
import 'package:awrad/services/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Settings displays Guest Mode, Manage Awrad, multiple Reminders, and Developer Mode',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guest Mode'), findsOneWidget);
    expect(find.text('Manage Awrad Tasks'), findsOneWidget);
    expect(find.text('12 active · Edit, delete, or reorder'), findsOneWidget);

    // Open Manage Awrad sheet
    await tester.tap(find.text('Manage Awrad Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Manage Awrad'), findsOneWidget);
    expect(find.text('Read Quran'), findsOneWidget);

    // Dismiss sheet
    Navigator.of(tester.element(find.text('Manage Awrad'))).pop();
    await tester.pumpAndSettle();

    // Scroll to Daily Reminders and add two reminders via settingsProvider
    await tester.scrollUntilVisible(
      find.text('Daily Reminders'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Daily Reminders'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.text('Daily Reminders')),
    );
    await container
        .read(settingsProvider.notifier)
        .addReminder(const TimeOfDay(hour: 6, minute: 0));
    await container
        .read(settingsProvider.notifier)
        .addReminder(const TimeOfDay(hour: 20, minute: 30));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Delete reminder'), findsNWidgets(2));

    // Keep Screen Awake is hidden until Developer Mode is unlocked (7 taps on version)
    expect(find.text('Keep Screen Awake'), findsNothing);

    final versionFinder = find.text('Awrad v1.0.0');
    await tester.scrollUntilVisible(
      versionFinder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    for (int i = 0; i < 7; i++) {
      await tester.tap(versionFinder);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('DEVELOPER'), findsOneWidget);
    expect(find.text('Keep Screen Awake'), findsOneWidget);
  });
}
