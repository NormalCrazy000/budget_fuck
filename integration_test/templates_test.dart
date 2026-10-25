// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction_template.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage();
  });

  testWidgets('Create templates, apply them to a month, check the home screen',
      (tester) async {
    // Pre-fill the categories needed by the category picker
    final categoryBox = Hive.box<Category>('categories');
    await categoryBox.put('c1', Category(id: 'c1', name: 'Stipendio'));
    await categoryBox.put('c2', Category(id: 'c2', name: 'Affitto'));

    await startApp(tester);

    // === Go to the Templates screen ===
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();

    expect(find.text('Template'), findsOneWidget);
    expect(find.text('Nessun template'), findsOneWidget);
    print('OK: empty templates screen');

    // === Create the "Stipendio" template (income) ===
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo Template'), findsOneWidget);
    // Income is the default, but tap it to be sure
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
    // Enter the amount
    await tester.enterText(find.byType(TextFormField), '2000');
    // Pick the category in the searchable field
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stipendio').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Nessun template'), findsNothing);
    print('OK: Stipendio template created');

    // === Create the "Affitto" template (expense) ===
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uscita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '800');
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Affitto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('OK: Affitto template created');

    // === Back home ===
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // === Go to Apply Templates ===
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Applica Template'), findsOneWidget);
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('OK: apply templates screen with 2 templates');

    // === Select all and apply ===
    await tester.tap(find.text('Seleziona Tutti'));
    await tester.pumpAndSettle();

    expect(find.text('Applica (2)'), findsOneWidget);

    await tester.tap(find.text('Applica (2)'));
    await tester.pumpAndSettle();

    // === Back home - check the transactions ===
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('800'), findsWidgets);
    print('OK: templates applied, transactions shown on the home screen');

    print('\nTEST PASSED: creating and applying templates works');
  });

  testWidgets('Partial apply - select only some templates',
      (tester) async {
    // Pre-populate templates
    final templateBox = Hive.box<TransactionTemplate>('templates');
    await templateBox.put(
      't1',
      TransactionTemplate(
        id: 't1',
        category: 'Stipendio',
        amount: 2000,
        isIncome: true,
      ),
    );
    await templateBox.put(
      't2',
      TransactionTemplate(
        id: 't2',
        category: 'Affitto',
        amount: 800,
        isIncome: false,
      ),
    );
    await templateBox.put(
      't3',
      TransactionTemplate(
        id: 't3',
        category: 'Bollette',
        amount: 150,
        isIncome: false,
      ),
    );

    await startApp(tester);

    // Go to Apply Templates
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    // Select only Stipendio (first checkbox)
    final checkboxes = find.byType(CheckboxListTile);
    expect(checkboxes, findsNWidgets(3));

    // Tap on Stipendio checkbox
    await tester.tap(find.text('Stipendio'));
    await tester.pumpAndSettle();

    expect(find.text('Applica (1)'), findsOneWidget);

    await tester.tap(find.text('Applica (1)'));
    await tester.pumpAndSettle();

    // Only Stipendio must appear on the home screen
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsNothing);
    expect(find.text('Bollette'), findsNothing);
    print('OK: partial apply - only Stipendio applied');

    print('\nTEST PASSED: partial apply works');
  });

  testWidgets('Templates persist after close and reopen',
      (tester) async {
    // Create a template
    final templateBox = Hive.box<TransactionTemplate>('templates');
    await templateBox.put(
      't1',
      TransactionTemplate(
        id: 't1',
        category: 'Stipendio',
        amount: 2000,
        isIncome: true,
      ),
    );

    await startApp(tester);

    // Go to the templates and check
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();
    expect(find.text('Stipendio'), findsOneWidget);
    print('SESSION 1: template shown in the UI');

    // Check persistence: close and reopen the box directly
    // (without reloading the UI, since the providers keep references to the closed box)
    await Hive.box<TransactionTemplate>('templates').close();
    final reopened = await Hive.openBox<TransactionTemplate>('templates');
    expect(reopened.values.length, 1);
    expect(reopened.values.first.category, 'Stipendio');
    print('SESSION 2: template still there after reopening the box');

    print('\nTEST PASSED: templates persist');
  });
}
