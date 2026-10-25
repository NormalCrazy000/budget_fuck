// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage(categories: ['Stipendio', 'Affitto']);
  });

  testWidgets('Chiudere e riaprire app - verificare che i dati persistono',
      (tester) async {
    // === SESSIONE 1: Aggiungere transazioni ===
    await startApp(tester);

    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);
    print('SESSIONE 1: App avviata, nessuna transazione');

    await addTransaction(
      tester,
      category: 'Stipendio',
      amount: '2000',
      isIncome: true,
    );
    await addTransaction(
      tester,
      category: 'Affitto',
      amount: '750',
      isIncome: false,
    );

    // Verificare che le transazioni sono presenti
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('750'), findsWidgets);
    expect(find.textContaining('1.250'), findsWidgets); // bilancio
    print('SESSIONE 1: Stipendio 2000 e Affitto 750 aggiunti, bilancio 1250');

    // === CHIUSURA APP: chiudere il box, come alla chiusura dell'app ===
    await Hive.box<Transaction>('transactions').close();
    print('SESSIONE 1: App chiusa (Hive box closed)');

    // === SESSIONE 2: Riavviare l'app (riapre il box come main()) ===
    await startApp(tester);
    print('SESSIONE 2: App riavviata');

    // === VERIFICHE PERSISTENZA ===
    // Le transazioni devono essere ancora presenti
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('SESSIONE 2: OK - Transazioni ancora visibili nella lista');

    // I totali devono essere gli stessi
    expect(find.textContaining('2.000'), findsWidgets); // entrate
    expect(find.textContaining('750'), findsWidgets); // uscite
    expect(find.textContaining('1.250'), findsWidgets); // bilancio
    print('SESSIONE 2: OK - Totali invariati (entrate 2000, uscite 750, bilancio 1250)');

    // Il messaggio "nessuna transazione" NON deve apparire
    expect(find.text('Nessuna transazione questo mese'), findsNothing);
    print('SESSIONE 2: OK - Nessun messaggio "nessuna transazione"');

    print('\nTEST PASSED: I dati persistono dopo chiusura e riapertura dell\'app');
  });
}
