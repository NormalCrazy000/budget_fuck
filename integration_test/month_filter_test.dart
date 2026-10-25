// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage();
    final box = Hive.box<Transaction>('transactions');

    // Insert transactions in different months directly into the DB
    final now = DateTime.now();

    // Current month: 2 transactions
    await box.put(
      'current_1',
      Transaction(
        id: 'current_1',
        category: 'Stipendio Febbraio',
        amount: 2000,
        isIncome: true,
        date: DateTime(now.year, now.month, 10),
      ),
    );
    await box.put(
      'current_2',
      Transaction(
        id: 'current_2',
        category: 'Affitto Febbraio',
        amount: 800,
        isIncome: false,
        date: DateTime(now.year, now.month, 5),
      ),
    );

    // Previous month: 1 transaction
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    await box.put(
      'prev_1',
      Transaction(
        id: 'prev_1',
        category: 'Stipendio Gennaio',
        amount: 1800,
        isIncome: true,
        date: DateTime(prevYear, prevMonth, 15),
      ),
    );

    // Next month: 1 transaction
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    await box.put(
      'next_1',
      Transaction(
        id: 'next_1',
        category: 'Previsione Marzo',
        amount: 500,
        isIncome: false,
        date: DateTime(nextYear, nextMonth, 20),
      ),
    );
  });

  testWidgets('Change month and check the transaction filter', (tester) async {
    await startApp(tester);

    // === CURRENT MONTH ===
    // Only the current month's transactions must be shown
    expect(find.text('Stipendio Febbraio'), findsOneWidget);
    expect(find.text('Affitto Febbraio'), findsOneWidget);
    // No transactions from other months
    expect(find.text('Stipendio Gennaio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    // Totals: income 2000, expenses 800, balance 1200
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('800'), findsWidgets);
    expect(find.textContaining('1.200'), findsWidgets);
    print('OK: current month - 2 transactions, correct totals');

    // === GO TO THE PREVIOUS MONTH ===
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Only the previous month's transaction must be shown
    expect(find.text('Stipendio Gennaio'), findsOneWidget);
    // No transactions from the current or next month
    expect(find.text('Stipendio Febbraio'), findsNothing);
    expect(find.text('Affitto Febbraio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    // Totals: income 1800, expenses 0, balance 1800
    expect(find.textContaining('1.800'), findsWidgets);
    print('OK: previous month - only its transaction, totals recomputed');

    // === GO FORWARD 2 MONTHS (back to current, then next) ===
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // Only the next month's transaction must be shown
    expect(find.text('Previsione Marzo'), findsOneWidget);
    // No transactions from other months
    expect(find.text('Stipendio Febbraio'), findsNothing);
    expect(find.text('Affitto Febbraio'), findsNothing);
    expect(find.text('Stipendio Gennaio'), findsNothing);
    // Totals: income 0, expenses 500, balance -500
    expect(find.textContaining('500'), findsWidgets);
    print('OK: next month - only its transaction, totals recomputed');

    // === BACK TO THE CURRENT MONTH ===
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio Febbraio'), findsOneWidget);
    expect(find.text('Affitto Febbraio'), findsOneWidget);
    expect(find.text('Stipendio Gennaio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    print('OK: back to the current month - transactions restored');

    print('\nTEST PASSED: the month filter works');
  });
}
