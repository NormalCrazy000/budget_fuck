import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/template_provider.dart';
import 'package:budget_fuck/screens/templates_screen.dart';

/// Fake TemplateProvider that does not depend on Hive.
class FakeTemplateProvider extends ChangeNotifier implements TemplateProvider {
  final List<TransactionTemplate> _templates = [];

  @override
  List<TransactionTemplate> get templates => List.unmodifiable(_templates);

  @override
  List<TransactionTemplate> get incomeTemplates =>
      _templates.where((t) => t.isIncome).toList();

  @override
  List<TransactionTemplate> get expenseTemplates =>
      _templates.where((t) => !t.isIncome).toList();

  @override
  Future<void> addTemplate(TransactionTemplate template) async {
    _templates.add(template);
    notifyListeners();
  }

  @override
  Future<void> deleteTemplate(String id) async {
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  @override
  Future<void> replaceAll(List<TransactionTemplate> tmpls) async {
    _templates
      ..clear()
      ..addAll(tmpls);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<TransactionTemplate> tmpls) async {
    final ids = _templates.map((t) => t.id).toSet();
    _templates.addAll(tmpls.where((t) => !ids.contains(t.id)));
    notifyListeners();
  }
}

TransactionTemplate _tmpl(String id, String category, {bool isIncome = false}) {
  return TransactionTemplate(
    id: id,
    amount: 100,
    isIncome: isIncome,
    category: category,
  );
}

void main() {
  late FakeTemplateProvider provider;

  setUp(() {
    provider = FakeTemplateProvider();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<TemplateProvider>.value(
        value: provider,
        child: const TemplatesScreen(),
      ),
    );
  }

  final searchField = find.widgetWithText(TextField, 'Cerca per categoria');

  testWidgets('empty list shows "Nessun template" and the search bar',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Nessun template'), findsOneWidget);
    expect(searchField, findsOneWidget);
  });

  testWidgets('search filters templates by category', (tester) async {
    await provider.addAll([
      _tmpl('1', 'Stipendio', isIncome: true),
      _tmpl('2', 'Affitto'),
      _tmpl('3', 'Bollette luce'),
    ]);
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'bollette');
    await tester.pumpAndSettle();

    expect(find.text('Bollette luce'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);
    expect(find.text('Affitto'), findsNothing);
  });

  testWidgets('shows "Nessun risultato" when the search finds nothing',
      (tester) async {
    await provider.addTemplate(_tmpl('1', 'Affitto'));
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('Nessun risultato'), findsOneWidget);
    expect(find.text('Nessun template'), findsNothing);
  });
}
