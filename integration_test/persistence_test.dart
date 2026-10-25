// The prints show the progress of each step during integration tests.
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

  testWidgets('Close and reopen the app - data persists',
      (tester) async {
    // === SESSION 1: add transactions ===
    await startApp(tester);

    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);
    print('SESSION 1: app started, no transactions');

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

    // The transactions must be there
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('750'), findsWidgets);
    expect(find.textContaining('1.250'), findsWidgets); // balance
    print('SESSION 1: Stipendio 2000 and Affitto 750 added, balance 1250');

    // === APP CLOSE: close the box, as when the app closes ===
    await Hive.box<Transaction>('transactions').close();
    print('SESSION 1: app closed (Hive box closed)');

    // === SESSION 2: restart the app (reopens the box like main()) ===
    await startApp(tester);
    print('SESSION 2: app restarted');

    // === PERSISTENCE CHECKS ===
    // The transactions must still be there
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    print('SESSION 2: OK - transactions still in the list');

    // The totals must be the same
    expect(find.textContaining('2.000'), findsWidgets); // income
    expect(find.textContaining('750'), findsWidgets); // expenses
    expect(find.textContaining('1.250'), findsWidgets); // balance
    print('SESSION 2: OK - totals unchanged (income 2000, expenses 750, balance 1250)');

    // The "no transactions" message must NOT appear
    expect(find.text('Nessuna transazione questo mese'), findsNothing);
    print('SESSION 2: OK - no "no transactions" message');

    print('\nTEST PASSED: data persists after closing and reopening the app');
  });
}
