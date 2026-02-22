import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/widgets/template_tile.dart';

void main() {
  late TransactionTemplate template;
  late bool deleted;

  setUp(() {
    deleted = false;
    template = TransactionTemplate(
      id: '1',
      amount: 800.0,
      isIncome: false,
      category: 'Affitto',
    );
  });

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            TemplateTile(
              template: template,
              onDelete: () => deleted = true,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('swipe mostra il dialog di conferma', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conferma eliminazione'), findsOneWidget);
    expect(
      find.text('Sei sicuro di voler eliminare Affitto?'),
      findsOneWidget,
    );
  });

  testWidgets('annullare il dialog non elimina il template', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(deleted, false);
    expect(find.text('Affitto'), findsOneWidget);
  });

  testWidgets('confermare il dialog elimina il template', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(deleted, true);
  });
}
