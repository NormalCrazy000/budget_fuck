import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budget_fuck/widgets/category_picker_field.dart';

import '../helpers/localized_app.dart';

void main() {
  const categories = ['Affitto', 'Caffè', 'Spesa', 'Spese mediche'];

  late GlobalKey<FormState> formKey;
  String? selected;

  setUp(() {
    formKey = GlobalKey<FormState>();
    selected = null;
  });

  Widget buildWidget() {
    return localizedApp(
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

  /// Text field inside the DropdownMenu.
  final input = find.byType(TextField);

  /// Menu entry with the given text (the text also appears in the field,
  /// so only the menu entries are searched).
  Finder menuEntry(String label) => find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text(label),
      );

  testWidgets('typing filters the entries ignoring case and accents',
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

  testWidgets('picking an entry sets the value and passes validation',
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

  testWidgets('without a choice validation asks for a category',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    // Typed text alone is not enough: an entry must be picked
    await tester.enterText(input, 'Affitto');
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Select a category'), findsOneWidget);
    expect(selected, isNull);
  });

  testWidgets('editing the text after picking clears the selection',
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
