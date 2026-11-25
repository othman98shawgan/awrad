import 'package:awrad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'Settings opens Scheduled Reminders modal with notes and unlocks Developer Mode',
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

    // Open Scheduled Reminders modal and add a reminder with a note
    await tester.scrollUntilVisible(
      find.text('Scheduled Reminders'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Scheduled Reminders'));
    await tester.pumpAndSettle();

    expect(find.text('No reminders scheduled yet'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('New Reminder'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Evening Adhkar');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Evening Adhkar'), findsOneWidget);
    expect(find.byTooltip('Delete reminder'), findsOneWidget);

    // Dismiss modal
    Navigator.of(tester.element(find.text('Scheduled Reminders').last)).pop();
    await tester.pumpAndSettle();

    expect(find.text('1 active · 1 total'), findsOneWidget);

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
