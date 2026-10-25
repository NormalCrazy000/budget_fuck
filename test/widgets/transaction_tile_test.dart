import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/widgets/transaction_tile.dart';

import '../helpers/localized_app.dart';

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
    return localizedApp(
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

  testWidgets('swipe shows the confirmation dialog', (tester) async {
    await tester.pumpWidget(buildWidget());

    // Swipe left
    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm deletion'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete Alimentari?'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the dialog keeps the transaction', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, false);
    // The transaction is still visible
    expect(find.text('Alimentari'), findsOneWidget);
  });

  testWidgets('confirming the dialog deletes the transaction', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, true);
  });
}
