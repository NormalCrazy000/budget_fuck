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
}
