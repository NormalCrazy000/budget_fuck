import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/widgets/confirm_delete_dialog.dart';

void main() {
  group('showConfirmDeleteDialog', () {
    testWidgets('mostra titolo, messaggio e pulsanti corretti', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  showConfirmDeleteDialog(context, 'Alimentari'),
              child: const Text('Apri'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();

      expect(find.text('Conferma eliminazione'), findsOneWidget);
      expect(
        find.text('Sei sicuro di voler eliminare Alimentari?'),
        findsOneWidget,
      );
      expect(find.text('Annulla'), findsOneWidget);
      expect(find.text('Elimina'), findsOneWidget);
    });

    testWidgets('Annulla restituisce false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result =
                    await showConfirmDeleteDialog(context, 'Alimentari');
              },
              child: const Text('Apri'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annulla'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('Elimina restituisce true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result =
                    await showConfirmDeleteDialog(context, 'Alimentari');
              },
              child: const Text('Apri'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Apri'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elimina'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
