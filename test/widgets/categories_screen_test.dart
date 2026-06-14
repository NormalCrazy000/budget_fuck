import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/providers/category_provider.dart';
import 'package:budget_fuck/screens/categories_screen.dart';

/// Fake CategoryProvider che non dipende da Hive.
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

  testWidgets('swipe mostra il dialog di conferma', (tester) async {
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

  testWidgets('confermare il dialog elimina la categoria', (tester) async {
    await provider.addCategory('Alimentari');
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.text('Alimentari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();

    expect(provider.categories, isEmpty);
  });

  testWidgets('annullare il dialog non elimina la categoria', (tester) async {
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
    'aggiungere una categoria via dialog non lancia errori Flutter',
    (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Apre il dialog tramite FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nuova Categoria'), findsOneWidget);

      // Digita il nome della categoria
      await tester.enterText(find.byType(TextField), 'Trasporti');
      await tester.pumpAndSettle();

      // Conferma
      await tester.tap(find.text('Aggiungi'));
      await tester.pumpAndSettle();

      // Il dialog deve essere chiuso
      expect(find.text('Nuova Categoria'), findsNothing);

      // La categoria deve comparire nella lista
      expect(find.text('Trasporti'), findsOneWidget);
      expect(provider.categories.length, 1);

      // Nessuna eccezione Flutter deve essere stata sollevata
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'aggiungere una categoria via invio da tastiera non lancia errori Flutter',
    (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Salute');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Nuova Categoria'), findsNothing);
      expect(find.text('Salute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
