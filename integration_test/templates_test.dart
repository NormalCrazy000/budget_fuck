// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/main.dart' as app;

import 'test_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Hive.init(testStoragePath);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    final box = await Hive.openBox<Transaction>('transactions');
    await box.clear();
    final templateBox = await Hive.openBox<TransactionTemplate>('templates');
    await templateBox.clear();
    final categoryBox = await Hive.openBox<Category>('categories');
    await categoryBox.clear();
  });

  testWidgets('Creare template, applicarli a un mese, verificare nella home',
      (tester) async {
    // Pre-popolare le categorie necessarie per il dropdown
    final categoryBox = Hive.box<Category>('categories');
    await categoryBox.put('c1', Category(id: 'c1', name: 'Stipendio'));
    await categoryBox.put('c2', Category(id: 'c2', name: 'Affitto'));

    app.runBudgetApp(storagePath: testStoragePath);
    await tester.pumpAndSettle();

    // === Navigare alla schermata Template ===
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();

    expect(find.text('Template'), findsOneWidget);
    expect(find.text('Nessun template'), findsOneWidget);
    print('OK: Schermata template vuota');

    // === Creare template "Stipendio" (entrata) ===
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo Template'), findsOneWidget);
    // Default è già Entrata, ma tappiamo per sicurezza
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
    // Inserire importo
    await tester.enterText(find.byType(TextFormField), '2000');
    // Selezionare categoria dal campo con ricerca
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stipendio').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Nessun template'), findsNothing);
    print('OK: Template Stipendio creato');

    // === Creare template "Affitto" (uscita) ===
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
    print('OK: Template Affitto creato');

    // === Tornare alla home ===
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // === Navigare ad Applica Template ===
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Applica Template'), findsOneWidget);
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('OK: Schermata applica template con 2 template');

    // === Selezionare tutti e applicare ===
    await tester.tap(find.text('Seleziona Tutti'));
    await tester.pumpAndSettle();

    expect(find.text('Applica (2)'), findsOneWidget);

    await tester.tap(find.text('Applica (2)'));
    await tester.pumpAndSettle();

    // === Siamo tornati alla home - verificare le transazioni ===
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('800'), findsWidgets);
    print('OK: Template applicati, transazioni visibili nella home');

    print('\nTEST PASSED: Creazione e applicazione template funzionano');
  });

  testWidgets('Applicazione parziale - selezionare solo alcuni template',
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

    app.runBudgetApp(storagePath: testStoragePath);
    await tester.pumpAndSettle();

    // Navigare ad Applica Template
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle();

    // Selezionare solo Stipendio (primo checkbox)
    final checkboxes = find.byType(CheckboxListTile);
    expect(checkboxes, findsNWidgets(3));

    // Tap on Stipendio checkbox
    await tester.tap(find.text('Stipendio'));
    await tester.pumpAndSettle();

    expect(find.text('Applica (1)'), findsOneWidget);

    await tester.tap(find.text('Applica (1)'));
    await tester.pumpAndSettle();

    // Solo Stipendio deve apparire nella home
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsNothing);
    expect(find.text('Bollette'), findsNothing);
    print('OK: Applicazione parziale - solo Stipendio applicato');

    print('\nTEST PASSED: Applicazione parziale funziona');
  });

  testWidgets('Template persistono dopo chiusura e riapertura',
      (tester) async {
    // Creare template
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

    app.runBudgetApp(storagePath: testStoragePath);
    await tester.pumpAndSettle();

    // Navigare ai template e verificare
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();
    expect(find.text('Stipendio'), findsOneWidget);
    print('SESSIONE 1: Template presente nella UI');

    // Verificare persistenza: chiudere e riaprire il box direttamente
    // (senza ricaricare la UI, perché i provider mantengono riferimenti al box chiuso)
    await Hive.box<TransactionTemplate>('templates').close();
    final reopened = await Hive.openBox<TransactionTemplate>('templates');
    expect(reopened.values.length, 1);
    expect(reopened.values.first.category, 'Stipendio');
    print('SESSIONE 2: Template ancora presente dopo riapertura box');

    print('\nTEST PASSED: Template persistono');
  });
}
