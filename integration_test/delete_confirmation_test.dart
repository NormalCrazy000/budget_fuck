// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
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
    testWidgets('transazione: annulla non elimina, conferma elimina',
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

      // Swipe per eliminare - annulla
      await swipeToDelete(tester, 'Stipendio');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe di nuovo - conferma
      await swipeToDelete(tester, 'Stipendio');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(find.text('Stipendio'), findsNothing);
      print('OK: Conferma eliminazione transazione funziona');
    });

    testWidgets('template: annulla non elimina, conferma elimina',
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

      // Navigare alla schermata Template
      await tester.tap(find.byIcon(Icons.list_alt));
      await tester.pumpAndSettle();

      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe per eliminare - annulla
      await swipeToDelete(tester, 'Stipendio');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      expect(find.text('Stipendio'), findsOneWidget);

      // Swipe e conferma
      await swipeToDelete(tester, 'Stipendio');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      // Aspetta la dismiss animation
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Stipendio'), findsNothing);
      print('OK: Conferma eliminazione template funziona');
    });

    testWidgets('categoria: annulla non elimina, conferma elimina',
        (tester) async {
      final categoryBox = Hive.box<Category>('categories');
      await categoryBox.put(
        'c1',
        Category(id: 'c1', name: 'Alimentari'),
      );

      await startApp(tester);

      // Navigare alla schermata Categorie
      await tester.tap(find.byIcon(Icons.category_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Alimentari'), findsOneWidget);

      // Swipe per eliminare - annulla
      await swipeToDelete(tester, 'Alimentari');
      expect(find.text('Conferma eliminazione'), findsOneWidget);

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();
      // Aspetta che il Dismissible torni in posizione
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Alimentari'), findsOneWidget);

      // Swipe e conferma
      await swipeToDelete(tester, 'Alimentari');
      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Alimentari'), findsNothing);
      print('OK: Conferma eliminazione categoria funziona');
    });
  });
}
