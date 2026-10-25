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

/// Campo di testo dentro il dialog "Nuova Categoria"
/// (la schermata ha anche la barra di ricerca).
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
      await tester.enterText(dialogTextField, 'Trasporti');
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

      await tester.enterText(dialogTextField, 'Salute');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Nuova Categoria'), findsNothing);
      expect(find.text('Salute'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('ricerca', () {
    /// Barra di ricerca in cima alla lista (fuori dal dialog).
    final searchField = find.widgetWithText(TextField, 'Cerca categoria');

    setUp(() async {
      await provider.addCategory('Spesa');
      await provider.addCategory('Spese mediche');
      await provider.addCategory('Caffè');
      await provider.addCategory('Affitto');
    });

    testWidgets('filtra la lista mentre si scrive', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'spes');
      await tester.pumpAndSettle();

      expect(find.text('Spesa'), findsOneWidget);
      expect(find.text('Spese mediche'), findsOneWidget);
      expect(find.text('Affitto'), findsNothing);
      expect(find.text('Caffè'), findsNothing);
    });

    testWidgets('ignora gli accenti', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'caffe');
      await tester.pumpAndSettle();

      expect(find.text('Caffè'), findsOneWidget);
      expect(find.text('Spesa'), findsNothing);
    });

    testWidgets('mostra "Nessun risultato" se non trova nulla', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(searchField, 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('Nessun risultato'), findsOneWidget);
      expect(find.text('Nessuna categoria'), findsNothing);
    });

    testWidgets('il pulsante X svuota la ricerca e mostra tutto',
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

  group('suggerimenti nel dialog', () {
    setUp(() async {
      await provider.addCategory('Spesa');
      await provider.addCategory('Spese mediche');
      await provider.addCategory('Affitto');
    });

    testWidgets('mostra le categorie simili già esistenti', (tester) async {
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

    testWidgets('nessun suggerimento con campo vuoto o senza somiglianze',
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
