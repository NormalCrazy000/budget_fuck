// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Clean the database before each test
    await resetStorage(categories: ['Stipendio', 'Affitto']);
  });

  testWidgets('Add income and expense and check they appear in the list',
      (tester) async {
    await startApp(tester);

    // Initial state: no transactions
    expect(find.text('No transactions this month'), findsOneWidget);

    // --- Add an INCOME ---
    await addTransaction(
      tester,
      category: 'Stipendio',
      amount: '1500',
      isIncome: true,
    );

    // Back home - the income must appear
    expect(find.text('Stipendio'), findsOneWidget);
    // The "no transactions" message must be gone
    expect(find.text('No transactions this month'), findsNothing);

    // --- Add an EXPENSE ---
    await addTransaction(
      tester,
      category: 'Affitto',
      amount: '800',
      isIncome: false,
    );

    // Both transactions must appear in the list
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);

    // Check the totals
    // Income: 1500, expenses: 800, balance: 700
    expect(find.textContaining('1,500'), findsWidgets); // income + in the tile
    expect(find.textContaining('800'), findsWidgets); // expenses + in the tile
    expect(find.textContaining('700.00'), findsWidgets); // balance

    print('TEST PASSED: income and expense added and shown in the list');
  });
}
