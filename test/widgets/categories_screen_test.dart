import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/providers/category_provider.dart';
import 'package:budget_fuck/screens/categories_screen.dart';

/// Fake CategoryProvider that does not depend on Hive.
class FakeCategoryProvider extends ChangeNotifier implements CategoryProvider {
  final List<Category> _categories = [];

  @override
  List<Category> get categories => List.unmodifiable(_categories);

  @override
  Future<void> addCategory(String name) async {
    _categories.add(Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    ));
    notifyListeners();
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  @override
  bool categoryExists(String name) {
    return _categories.any(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  @override
  Future<void> replaceAll(List<Category> cats) async {
    _categories
      ..clear()
      ..addAll(cats);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<Category> cats) async {
    final ids = _categories.map((c) => c.id).toSet();
    _categories.addAll(cats.where((c) => !ids.contains(c.id)));
    notifyListeners();
  }
}

/// Text field inside the new category dialog
/// (the screen also has the search bar).
final dialogTextField = find.descendant(
  of: find.byType(AlertDialog),
  matching: find.byType(TextField),
);

void main() {
  late FakeCategoryProvider provider;

  setUp(() {
    provider = FakeCategoryProvider();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<CategoryProvider>.value(
        value: provider,
        child: const CategoriesScreen(),
      ),
    );
  }

  testWidgets('swipe shows the confirmation dialog', (tester) async {
    await provider.addCategory('Alimentari');
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Conferma eliminazione'), findsOneWidget);
    expect(
      find.text('Sei sicuro di voler eliminare Alimentari?'),
      findsOneWidget,
    );
  });

  testWidgets('confirming the dialog deletes the category', (tester) async {
    await provider.addCategory('Alimentari');
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(provider.categories, isEmpty);
  });

  testWidgets('cancelling the dialog keeps the category', (tester) async {
    await provider.addCategory('Alimentari');
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    expect(provider.categories.length, 1);
    expect(find.text('Alimentari'), findsOneWidget);
  });

  testWidgets(
    'adding a category via the dialog throws no Flutter errors',
    (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Open the dialog with the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuova Categoria'), findsOneWidget);

      // Type the category name
      await tester.enterText(dialogTextField, 'Trasporti');
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Aggiungi'));
      await tester.pumpAndSettle();

      // The dialog must be closed
      expect(find.text('Nuova Categoria'), findsNothing);

      // The category must appear in the list
      expect(find.text('Trasporti'), findsOneWidget);
      expect(provider.categories.length, 1);

      // No Flutter exception must have been thrown
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'adding a category with the keyboard enter key throws no Flutter errors',
    (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(dialogTextField, 'Salute');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Nuova Categoria'), findsNothing);
      expect(find.text('Salute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('search', () {
    /// Search bar at the top of the list (outside the dialog).
    final searchField = find.widgetWithText(TextField, 'Cerca categoria');

    setUp(() async {
      await provider.addCategory('Spesa');
      await provider.addCategory('Spese mediche');
      await provider.addCategory('Caffè');
      await provider.addCategory('Affitto');
    });

    testWidgets('filters the list while typing', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'spes');
      await tester.pumpAndSettle();

      expect(find.text('Spesa'), findsOneWidget);
      expect(find.text('Spese mediche'), findsOneWidget);
      expect(find.text('Affitto'), findsNothing);
      expect(find.text('Caffè'), findsNothing);
    });

    testWidgets('ignores accents', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'caffe');
      await tester.pumpAndSettle();

      expect(find.text('Caffè'), findsOneWidget);
      expect(find.text('Spesa'), findsNothing);
    });

    testWidgets('shows "Nessun risultato" when nothing matches', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('Nessun risultato'), findsOneWidget);
      expect(find.text('Nessuna categoria'), findsNothing);
    });

    testWidgets('the X button clears the search and shows everything',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'xyz');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancella ricerca'));
      await tester.pumpAndSettle();

      expect(find.text('Spesa'), findsOneWidget);
      expect(find.text('Affitto'), findsOneWidget);
      expect(find.byTooltip('Cancella ricerca'), findsNothing);
    });
  });

  group('suggestions in the dialog', () {
    setUp(() async {
      await provider.addCategory('Spesa');
      await provider.addCategory('Spese mediche');
      await provider.addCategory('Affitto');
    });

    testWidgets('shows similar existing categories', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(dialogTextField, 'spe');
      await tester.pumpAndSettle();

      final chips = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Chip),
      );
      expect(find.text('Già esistenti:'), findsOneWidget);
      expect(chips, findsNWidgets(2));
      expect(
        find.descendant(of: chips, matching: find.text('Spesa')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chips, matching: find.text('Spese mediche')),
        findsOneWidget,
      );
    });

    testWidgets('no suggestions with an empty field or no similar names',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Già esistenti:'), findsNothing);

      await tester.enterText(dialogTextField, 'Trasporti');
      await tester.pumpAndSettle();

      expect(find.text('Già esistenti:'), findsNothing);
    });
  });
}
