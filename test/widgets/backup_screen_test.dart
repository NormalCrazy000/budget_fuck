import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/category_provider.dart';
import 'package:budget_fuck/providers/template_provider.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'package:budget_fuck/screens/backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeTransactionProvider extends ChangeNotifier
    implements TransactionProvider {
  final List<Transaction> _all = [];

  @override
  List<Transaction> get allTransactions => List.unmodifiable(_all);

  @override
  List<Transaction> get transactions => _all;

  @override
  int get selectedMonth => DateTime.now().month;

  @override
  int get selectedYear => DateTime.now().year;

  @override
  double get totalIncome => 0;

  @override
  double get totalExpense => 0;

  @override
  double get balance => 0;

  @override
  void previousMonth() {}

  @override
  void nextMonth() {}

  @override
  void setMonth(int month, int year) {}

  @override
  Future<void> addTransaction(Transaction t) async => _all.add(t);

  @override
  Future<void> deleteTransaction(String id) async =>
      _all.removeWhere((t) => t.id == id);

  @override
  Future<void> replaceAll(List<Transaction> transactions) async {
    _all
      ..clear()
      ..addAll(transactions);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<Transaction> transactions) async {
    final ids = _all.map((t) => t.id).toSet();
    _all.addAll(transactions.where((t) => !ids.contains(t.id)));
    notifyListeners();
  }
}

class _FakeCategoryProvider extends ChangeNotifier implements CategoryProvider {
  final List<Category> _cats = [];

  @override
  List<Category> get categories => List.unmodifiable(_cats);

  @override
  Future<void> addCategory(String name) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  bool categoryExists(String name) => false;

  @override
  Future<void> replaceAll(List<Category> cats) async {
    _cats
      ..clear()
      ..addAll(cats);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<Category> cats) async {
    final ids = _cats.map((c) => c.id).toSet();
    _cats.addAll(cats.where((c) => !ids.contains(c.id)));
    notifyListeners();
  }
}

class _FakeTemplateProvider extends ChangeNotifier implements TemplateProvider {
  final List<TransactionTemplate> _tmpls = [];

  @override
  List<TransactionTemplate> get templates => List.unmodifiable(_tmpls);

  @override
  List<TransactionTemplate> get incomeTemplates =>
      _tmpls.where((t) => t.isIncome).toList();

  @override
  List<TransactionTemplate> get expenseTemplates =>
      _tmpls.where((t) => !t.isIncome).toList();

  @override
  Future<void> addTemplate(TransactionTemplate t) async => _tmpls.add(t);

  @override
  Future<void> deleteTemplate(String id) async =>
      _tmpls.removeWhere((t) => t.id == id);

  @override
  Future<void> replaceAll(List<TransactionTemplate> tmpls) async {
    _tmpls
      ..clear()
      ..addAll(tmpls);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<TransactionTemplate> tmpls) async {
    final ids = _tmpls.map((t) => t.id).toSet();
    _tmpls.addAll(tmpls.where((t) => !ids.contains(t.id)));
    notifyListeners();
  }
}

Widget _buildWidget() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransactionProvider>.value(
        value: _FakeTransactionProvider(),
      ),
      ChangeNotifierProvider<CategoryProvider>.value(
        value: _FakeCategoryProvider(),
      ),
      ChangeNotifierProvider<TemplateProvider>.value(
        value: _FakeTemplateProvider(),
      ),
    ],
    child: const MaterialApp(home: BackupScreen()),
  );
}

void main() {
  testWidgets('mostra il titolo Backup & Ripristino', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Backup & Ripristino'), findsOneWidget);
  });

  testWidgets('mostra il pulsante Esporta dati', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Esporta dati'), findsOneWidget);
  });

  testWidgets('mostra il pulsante Importa backup', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Importa backup'), findsOneWidget);
  });

  testWidgets('mostra il testo descrittivo', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(
      find.textContaining('Esporta tutti i dati'),
      findsOneWidget,
    );
  });

  testWidgets('non solleva eccezioni Flutter al rendering', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(tester.takeException(), isNull);
  });
}
