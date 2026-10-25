import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/widgets/confirm_delete_dialog.dart';

import 'helpers/localized_app.dart';

void main() {
  group('showConfirmDeleteDialog', () {
    testWidgets('shows the right title, message and buttons', (tester) async {
      await tester.pumpWidget(
        localizedApp(
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

      expect(find.text('Confirm deletion'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete Alimentari?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Cancel returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        localizedApp(
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

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('Delete returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        localizedApp(
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

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
