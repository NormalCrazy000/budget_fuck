import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    final box = await Hive.openBox<Transaction>('transactions');
    await box.clear();
  });

  testWidgets('Chiudere e riaprire app - verificare che i dati persistono',
      (tester) async {
    // === SESSIONE 1: Aggiungere transazioni ===
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);
    print('SESSIONE 1: App avviata, nessuna transazione');

    // Aggiungere entrata
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Stipendio');
    await tester.enterText(find.byType(TextFormField).last, '2000');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Aggiungere uscita
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uscita'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Affitto');
    await tester.enterText(find.byType(TextFormField).last, '750');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Verificare che le transazioni sono presenti
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('750'), findsWidgets);
    expect(find.textContaining('1.250'), findsWidgets); // bilancio
    print('SESSIONE 1: Stipendio 2000 e Affitto 750 aggiunti, bilancio 1250');

    // === CHIUSURA APP: Chiudere Hive e rimuovere widget tree ===
    // Simuliamo la chiusura chiudendo il box
    await Hive.box<Transaction>('transactions').close();
    print('SESSIONE 1: App chiusa (Hive box closed)');

    // === SESSIONE 2: Riaprire l'app da zero ===
    // Riaprire il box (come fa main() al restart)
    await Hive.openBox<Transaction>('transactions');

    // Riavviare l'app completamente
    app.main();
    await tester.pumpAndSettle();
    print('SESSIONE 2: App riavviata');

    // === VERIFICHE PERSISTENZA ===
    // Le transazioni devono essere ancora presenti
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('SESSIONE 2: OK - Transazioni ancora visibili nella lista');

    // I totali devono essere gli stessi
    expect(find.textContaining('2.000'), findsWidgets); // entrate
    expect(find.textContaining('750'), findsWidgets);   // uscite
    expect(find.textContaining('1.250'), findsWidgets); // bilancio
    print('SESSIONE 2: OK - Totali invariati (entrate 2000, uscite 750, bilancio 1250)');

    // Il messaggio "nessuna transazione" NON deve apparire
    expect(find.text('Nessuna transazione questo mese'), findsNothing);
    print('SESSIONE 2: OK - Nessun messaggio "nessuna transazione"');

    print('\nTEST PASSED: I dati persistono dopo chiusura e riapertura dell\'app');
  });
}
