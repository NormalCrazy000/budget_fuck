import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/widgets/transaction_tile.dart';

void main() {
  late Transaction transaction;
  late bool deleted;

  setUp(() {
    deleted = false;
    transaction = Transaction(
      id: '1',
      amount: 50.0,
      isIncome: false,
      date: DateTime(2026, 1, 15),
      category: 'Alimentari',
    );
  });

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            TransactionTile(
              transaction: transaction,
              onDelete: () => deleted = true,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('swipe mostra il dialog di conferma', (tester) async {
    await tester.pumpWidget(buildWidget());

    // Swipe verso sinistra
    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conferma eliminazione'), findsOneWidget);
    expect(
      find.text('Sei sicuro di voler eliminare Alimentari?'),
      findsOneWidget,
    );
  });

  testWidgets('annullare il dialog non elimina la transazione', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(deleted, false);
    // La transazione è ancora visibile
    expect(find.text('Alimentari'), findsOneWidget);
  });

  testWidgets('confermare il dialog elimina la transazione', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(deleted, true);
  });
}
