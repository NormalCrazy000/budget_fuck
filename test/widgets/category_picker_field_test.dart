import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/widgets/category_picker_field.dart';

void main() {
  const categories = ['Affitto', 'Caffè', 'Spesa', 'Spese mediche'];

  late GlobalKey<FormState> formKey;
  String? selected;

  setUp(() {
    formKey = GlobalKey<FormState>();
    selected = null;
  });

  Widget buildWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: CategoryPickerField(
            categoryNames: categories,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
  }

  /// Campo di testo interno al DropdownMenu.
  final input = find.byType(TextField);

  /// Voce del menu con il testo dato (il testo compare anche nel campo,
  /// quindi si cerca solo dentro le voci del menu).
  Finder menuEntry(String label) => find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text(label),
      );

  testWidgets('scrivendo filtra le voci ignorando maiuscole e accenti',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(input);
    await tester.pumpAndSettle();

    await tester.enterText(input, 'SPE');
    await tester.pumpAndSettle();
    expect(menuEntry('Spesa'), findsOneWidget);
    expect(menuEntry('Spese mediche'), findsOneWidget);
    expect(menuEntry('Affitto'), findsNothing);

    await tester.enterText(input, 'caffe');
    await tester.pumpAndSettle();
    expect(menuEntry('Caffè'), findsOneWidget);
    expect(menuEntry('Spesa'), findsNothing);
  });

  testWidgets('scegliere una voce imposta il valore e supera la validazione',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(input);
    await tester.pumpAndSettle();

    await tester.enterText(input, 'aff');
    await tester.pumpAndSettle();
    await tester.tap(menuEntry('Affitto'));
    await tester.pumpAndSettle();

    expect(selected, 'Affitto');
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('senza scelta la validazione chiede una categoria',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    // Il testo digitato da solo non basta: serve scegliere una voce
    await tester.enterText(input, 'Affitto');
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Seleziona una categoria'), findsOneWidget);
    expect(selected, isNull);
  });

  testWidgets('modificare il testo dopo la scelta annulla la selezione',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.tap(input);
    await tester.pumpAndSettle();
    await tester.tap(menuEntry('Spesa'));
    await tester.pumpAndSettle();
    expect(selected, 'Spesa');

    await tester.enterText(input, 'Spes');
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(formKey.currentState!.validate(), isFalse);
  });
}
