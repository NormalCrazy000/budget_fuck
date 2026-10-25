// The prints show the progress of each step during integration tests.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage();
  });

  group('Delete confirmation dialog', () {
    testWidgets('transaction: cancel keeps it, confirm deletes it',
        (tester) async {
      final now = DateTime.now();
      final txBox = Hive.box<Transaction>('transactions');
      await txBox.put(
        'tx1',
        Transaction(
          id: 'tx1',
          amount: 100.0,
          isIncome: true,
          date: DateTime(now.year, now.month, 1),
          category: 'Stipendio',
        ),
      );

      await startApp(tester);

      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe to delete - cancel
      await swipeToDelete(tester, 'Stipendio');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe again - confirm
      await swipeToDelete(tester, 'Stipendio');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Stipendio'), findsNothing);
      print('OK: transaction delete confirmation works');
    });

    testWidgets('template: cancel keeps it, confirm deletes it',
        (tester) async {
      final templateBox = Hive.box<TransactionTemplate>('templates');
      await templateBox.put(
        't1',
        TransactionTemplate(
          id: 't1',
          amount: 2000,
          isIncome: true,
          category: 'Stipendio',
        ),
      );

      await startApp(tester);

      // Go to the Templates screen
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe to delete - cancel
      await swipeToDelete(tester, 'Stipendio');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe and confirm
      await swipeToDelete(tester, 'Stipendio');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      // Wait for the dismiss animation
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Stipendio'), findsNothing);
      print('OK: template delete confirmation works');
    });

    testWidgets('category: cancel keeps it, confirm deletes it',
        (tester) async {
      final categoryBox = Hive.box<Category>('categories');
      await categoryBox.put(
        'c1',
        Category(id: 'c1', name: 'Alimentari'),
      );

      await startApp(tester);

      // Go to the Categories screen
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Alimentari'), findsOneWidget);

      // Swipe to delete - cancel
      await swipeToDelete(tester, 'Alimentari');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      // Wait for the Dismissible to slide back
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Alimentari'), findsOneWidget);

      // Swipe and confirm
      await swipeToDelete(tester, 'Alimentari');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Alimentari'), findsNothing);
      print('OK: category delete confirmation works');
    });
  });
}
