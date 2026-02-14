import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    final box = await Hive.openBox<Transaction>('transactions');
    await box.clear();
    final templateBox = await Hive.openBox<TransactionTemplate>('templates');
    await templateBox.clear();
  });

  testWidgets('Creare template, applicarli a un mese, verificare nella home',
      (tester) async {
    app.main();
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
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Stipendio');
    await tester.enterText(find.byType(TextFormField).last, '2000');
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
    await tester.enterText(find.byType(TextFormField).first, 'Affitto');
    await tester.enterText(find.byType(TextFormField).last, '800');
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
        title: 'Stipendio',
        amount: 2000,
        isIncome: true,
      ),
    );
    await templateBox.put(
      't2',
      TransactionTemplate(
        id: 't2',
        title: 'Affitto',
        amount: 800,
        isIncome: false,
      ),
    );
    await templateBox.put(
      't3',
      TransactionTemplate(
        id: 't3',
        title: 'Bollette',
        amount: 150,
        isIncome: false,
      ),
    );

    app.main();
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
        title: 'Stipendio',
        amount: 2000,
        isIncome: true,
      ),
    );

    app.main();
    await tester.pumpAndSettle();

    // Navigare ai template e verificare
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();
    expect(find.text('Stipendio'), findsOneWidget);
    print('SESSIONE 1: Template presente');

    // Simulare chiusura
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await Hive.box<TransactionTemplate>('templates').close();
    await Hive.box<Transaction>('transactions').close();

    // Riaprire
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<TransactionTemplate>('templates');
    app.main();
    await tester.pumpAndSettle();

    // Navigare ai template e verificare persistenza
    await tester.tap(find.byIcon(Icons.list_alt));
    await tester.pumpAndSettle();
    expect(find.text('Stipendio'), findsOneWidget);
    print('SESSIONE 2: Template ancora presente');

    print('\nTEST PASSED: Template persistono');
  });
}
