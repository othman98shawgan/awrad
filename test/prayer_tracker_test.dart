import 'package:awrad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Prayer tab displays Muakkadah defaults without Before/partial labels',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Prayer'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Today's Prayer Status"), findsOneWidget);
    expect(find.text('0 / 5'), findsNWidgets(2));
    // Default Mu'akkadah (12 Rawatib + 17 Fard + 3 Witr = 32 rak'ahs)
    expect(find.text('0 / 32'), findsOneWidget);
    expect(find.textContaining('Before Sunnah'), findsNothing);
    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Isha & Witr'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha & Witr'), findsOneWidget);
  });

  testWidgets(
      'completing Fard marks prayer done and Masjid button tracks masjid count',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Prayer'),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Fajr's Fard (2) chip -> marks prayer done (1 / 5), 2 / 32 rak'ahs, no "partial" text
    await tester.tap(find.text('Fard (2)'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsOneWidget);
    expect(find.text('2 / 32'), findsOneWidget);
    expect(find.textContaining('partial'), findsNothing);

    // Tap Fajr's Masjid button -> In Masjid updates to 1 / 5
    await tester.tap(find.bySemanticsLabel('Fajr in Masjid'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsNWidgets(2));
  });

  testWidgets('Customize Sunnah sheet updates rakah totals with Mustahabbah preset',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: OradApp()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Prayer'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Customize Sunnah'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mu’akkadah + Mustahabbah'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Sunnah Settings'));
    await tester.pumpAndSettle();

    // Mu'akkadah + Mustahabbah adds 10 rak'ahs (Dhuhr +2, Asr +4, Maghrib +2, Isha +2) = 42
    expect(find.text('0 / 42'), findsOneWidget);
  });
}
