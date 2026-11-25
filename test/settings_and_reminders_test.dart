import 'package:awrad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings displays Guest Mode, Manage Awrad, and Daily Reminder',
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

    // Scroll to Daily Reminder and toggle ON
    await tester.scrollUntilVisible(
      find.text('Daily Reminder'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Daily Reminder'));
    await tester.pumpAndSettle();

    expect(find.text('Reminder Time'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('app_settings_v1'),
      contains('"dailyReminderEnabled":true'),
    );

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
