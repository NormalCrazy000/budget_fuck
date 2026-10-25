import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/widgets/template_tile.dart';

import '../helpers/localized_app.dart';

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
    return localizedApp(
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

  testWidgets('swipe shows the confirmation dialog', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Confirm deletion'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete Affitto?'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the dialog keeps the template', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, false);
    expect(find.text('Affitto'), findsOneWidget);
  });

  testWidgets('confirming the dialog deletes the template', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.drag(find.text('Affitto'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleted, true);
  });
}
