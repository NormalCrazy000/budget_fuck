// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage(
      categories: ['Stipendio', 'Affitto', 'Freelance', 'Spesa'],
    );
  });

  testWidgets('Totals update correctly',
      (tester) async {
    await startApp(tester);

    // --- Initial state: all totals at 0 ---
    // The cards show €0,00 for income, expenses, balance
    expect(find.textContaining('0,00'), findsWidgets);
    print('OK: initial totals are zero');

    // --- First income: Stipendio 2000 ---
    await addTransaction(
      tester,
      category: 'Stipendio',
      amount: '2000',
      isIncome: true,
    );

    // Income: 2.000,00 | Expenses: 0,00 | Balance: 2.000,00
    expect(find.textContaining('2.000'), findsWidgets);
    print('OK: after income 2000 - totals updated');

    // --- Expense: Affitto 800 ---
    await addTransaction(
      tester,
      category: 'Affitto',
      amount: '800',
      isIncome: false,
    );

    // Income: 2.000,00 | Expenses: 800,00 | Balance: 1.200,00
    expect(find.textContaining('2.000'), findsWidgets); // income
    expect(find.textContaining('800'), findsWidgets); // expenses
    expect(find.textContaining('1.200'), findsWidgets); // balance
    print('OK: after expense 800 - income 2000, expenses 800, balance 1200');

    // --- Second income: Freelance 500 ---
    await addTransaction(
      tester,
      category: 'Freelance',
      amount: '500',
      isIncome: true,
    );

    // Income: 2.500,00 | Expenses: 800,00 | Balance: 1.700,00
    expect(find.textContaining('2.500'), findsWidgets); // income
    expect(find.textContaining('800'), findsWidgets); // expenses
    expect(find.textContaining('1.700'), findsWidgets); // balance
    print('OK: after income 500 - income 2500, expenses 800, balance 1700');

    // --- Second expense: Spesa 300 ---
    await addTransaction(
      tester,
      category: 'Spesa',
      amount: '300',
      isIncome: false,
    );

    // Income: 2.500,00 | Expenses: 1.100,00 | Balance: 1.400,00
    expect(find.textContaining('2.500'), findsWidgets); // income
    expect(find.textContaining('1.100'), findsWidgets); // expenses
    expect(find.textContaining('1.400'), findsWidgets); // balance
    print('OK: after expense 300 - income 2500, expenses 1100, balance 1400');

    // --- Delete "Spesa" (swipe + confirm) and check the recomputed totals ---
    await swipeToDelete(tester, 'Spesa');
    await tester.tap(find.text('Elimina'));
    // Totals refresh once the delete on Hive has completed
    await waitFor(tester, find.textContaining('1.700'));

    // "Spesa" must no longer be visible
    expect(find.text('Spesa'), findsNothing);

    // Income: 2.500,00 | Expenses: 800,00 | Balance: 1.700,00
    // Check the 3 remaining transactions
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.500'), findsWidgets); // income unchanged
    expect(find.textContaining('1.700'), findsWidgets); // balance recomputed
    print('OK: after deleting Spesa - expenses back to 800, balance 1700');

    print('\nTEST PASSED: all totals update correctly');
  });
}
