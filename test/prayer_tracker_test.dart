import 'package:awrad/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Prayer tab displays status card and 5 daily prayers',
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
    expect(find.text('0 / 38'), findsOneWidget);
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
      'tapping segment chips updates partial rakahs and persists state',
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

    // Tap Fajr's Fard (2) chip -> partial prayer, 2/38 rakahs
    await tester.tap(find.text('Fard (2)'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 38'), findsOneWidget);
    expect(find.text('1 partial'), findsOneWidget);

    // Tap Fajr's circular toggle -> marks all Fajr segments done (4/4 rakahs)
    await tester.tap(find.bySemanticsLabel('Toggle Fajr'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 5'), findsNWidgets(2));
    expect(find.text('4 / 38'), findsOneWidget);
    expect(find.text('1 partial'), findsNothing);
  });
}
