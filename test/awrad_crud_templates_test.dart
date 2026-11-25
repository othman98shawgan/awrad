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
      'empty state opens templates modal, tap cycles status, and long-press opens Edit Wird sheet',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    expect(find.text('Your Awrad list is empty'), findsOneWidget);
    await tester.tap(find.text('Tap here to choose from templates'));
    await tester.pumpAndSettle();

    expect(find.text('Import Awrad Templates'), findsOneWidget);
    await tester.tap(find.text('Daily Essentials'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Progress'), findsOneWidget);
    expect(find.text('0 of 9 done'), findsOneWidget);

    final firstTask = find.text('Quran');

    // 1st tap on card: Done
    await tester.tap(firstTask);
    await tester.pumpAndSettle();
    expect(find.text('1 of 9 done'), findsOneWidget);

    // 2nd tap on card: Half done (no "Half done" text badge on card)
    await tester.tap(firstTask);
    await tester.pumpAndSettle();
    expect(find.text('Half done'), findsNothing);
    expect(find.text('0 of 9 done · 1 half done'), findsOneWidget);

    // 3rd tap on card: Not done
    await tester.tap(firstTask);
    await tester.pumpAndSettle();
    expect(find.text('0 of 9 done'), findsOneWidget);

    // Long press opens Edit Wird sheet
    await tester.longPress(firstTask);
    await tester.pumpAndSettle();
    expect(find.text('Edit Wird'), findsOneWidget);
  });

  testWidgets('adding a new Wird via sheet updates the Awrad list',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Wird').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Read Surah Al-Mulk',
    );
    await tester.tap(find.text('Add Wird'));
    await tester.pumpAndSettle();

    expect(find.text('All (1)'), findsOneWidget);
  });

  testWidgets('importing a template from Settings merges new tasks',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Import Awrad Templates'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning & Evening Adhkar'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Switch back to Awrad tab and confirm merged tasks increased total count.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Awrad'),
      ),
    );
    await tester.pumpAndSettle();

    // Starts empty, Morning & Evening Adhkar has 5 tasks -> 5 total.
    expect(find.text('All (5)'), findsOneWidget);
  });

  testWidgets('Manage Awrad supports swipe-to-delete', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

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
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage Awrad Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('9 active · Tap to edit or drag to reorder'),
        findsOneWidget);

    await tester.drag(find.text('Quran').last, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('8 active · Tap to edit or drag to reorder'),
        findsOneWidget);
  });
}
