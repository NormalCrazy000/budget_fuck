// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Starts in English (see resetStorage)
    await resetStorage();
  });

  testWidgets('Switch to Italian from Settings, choice survives a restart',
      (tester) async {
    await startApp(tester);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('No transactions this month'), findsOneWidget);
    print('OK: app in English');

    // Settings -> Language -> Italiano
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    // The settings screen itself is now in Italian
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('Lingua'), findsOneWidget);
    expect(find.text('Backup & Ripristino'), findsOneWidget);
    print('OK: settings screen switched to Italian');

    // Back home: labels in Italian
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Entrate'), findsOneWidget);
    expect(find.text('Uscite'), findsOneWidget);
    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);
    print('OK: home screen in Italian');

    // Restart the app: the choice is kept
    await startApp(tester);
    expect(find.text('Entrate'), findsOneWidget);
    print('OK: Italian kept after restart');

    print('\nTEST PASSED: language switch works and persists');
  });
}
