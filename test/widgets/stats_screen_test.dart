import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'package:budget_fuck/screens/stats_screen.dart';

import '../helpers/localized_app.dart';

/// Fake TransactionProvider that does not depend on Hive.
class FakeTransactionProvider extends ChangeNotifier
    implements TransactionProvider {
  final List<Transaction> _all = [];
  int _month;
  int _year;

  FakeTransactionProvider({int month = 6, int year = 2026})
      : _month = month,
        _year = year;

  @override
  int get selectedMonth => _month;

  @override
  int get selectedYear => _year;

  @override
  List<Transaction> get transactions => _all
      .where((t) => t.date.month == _month && t.date.year == _year)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  @override
  double get totalIncome => transactions
      .where((t) => t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  @override
  double get totalExpense => transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (s, t) => s + t.amount);

  @override
  double get balance => totalIncome - totalExpense;

  @override
  void previousMonth() {
    if (_month == 1) {
      _month = 12;
      _year--;
    } else {
      _month--;
    }
    notifyListeners();
  }

  @override
  void nextMonth() {
    if (_month == 12) {
      _month = 1;
      _year++;
    } else {
      _month++;
    }
    notifyListeners();
  }

  @override
  void setMonth(int month, int year) {
    _month = month;
    _year = year;
    notifyListeners();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    _all.add(transaction);
    notifyListeners();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _all.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  @override
  List<Transaction> get allTransactions => List.unmodifiable(_all);

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

Transaction _tx({
  required String id,
  required double amount,
  required bool isIncome,
  required String category,
  DateTime? date,
}) =>
    Transaction(
      id: id,
      amount: amount,
      isIncome: isIncome,
      date: date ?? DateTime(2026, 6, 1),
      category: category,
    );

void main() {
  late FakeTransactionProvider provider;

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    provider = FakeTransactionProvider();
  });

  Widget buildWidget() {
    return localizedApp(
      home: ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const StatsScreen(),
      ),
    );
  }

  testWidgets('shows the Expenses and Income tabs', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
  });

  testWidgets('empty Expenses tab shows a message', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('No expenses this month'), findsOneWidget);
  });

  testWidgets('empty Income tab shows a message', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('No income this month'), findsOneWidget);
  });

  testWidgets('shows a category with the right amount', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 50.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alimentari'), findsOneWidget);
    // the English format is "€50.00"
    expect(find.textContaining('50.00'), findsWidgets);
  });

  testWidgets('groups transactions of the same category', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 30.0, isIncome: false, category: 'Alimentari'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 20.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // 30 + 20 = 50 as the category total
    expect(find.textContaining('50.00'), findsWidgets);
    // two transactions
    expect(find.text('2 transactions'), findsOneWidget);
  });

  testWidgets('sorts categories by descending amount', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 10.0, isIncome: false, category: 'Bollette'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 80.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    final alimentariPos =
        tester.getTopLeft(find.text('Alimentari')).dy;
    final bollettePos =
        tester.getTopLeft(find.text('Bollette')).dy;

    expect(alimentariPos, lessThan(bollettePos));
  });

  testWidgets('shows 100% for a single category', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 100.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('100.0%'), findsOneWidget);
  });

  testWidgets('computes the right percentage with two categories', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 75.0, isIncome: false, category: 'Alimentari'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 25.0, isIncome: false, category: 'Trasporti'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('75.0%'), findsOneWidget);
    expect(find.text('25.0%'), findsOneWidget);
  });

  testWidgets('income and expenses are in separate tabs', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 100.0, isIncome: false, category: 'Spesa'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 200.0, isIncome: true, category: 'Stipendio'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Expenses tab: shows Spesa, not Stipendio
    expect(find.text('Spesa'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);

    // Switch to the income tab
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Spesa'), findsNothing);
  });

  testWidgets('left arrow goes to the previous month', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('MAY 2026'), findsOneWidget);
  });

  testWidgets('right arrow goes to the next month', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('JULY 2026'), findsOneWidget);
  });

  testWidgets('transactions of other months are not shown', (tester) async {
    await provider.addTransaction(
      _tx(
        id: '1',
        amount: 50.0,
        isIncome: false,
        category: 'Alimentari',
        date: DateTime(2026, 5, 1),
      ),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // The provider is on June 2026, the transaction is from May
    expect(find.text('No expenses this month'), findsOneWidget);
  });

  testWidgets('a single transaction shows singular text', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 10.0, isIncome: false, category: 'Altro'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('1 transaction'), findsOneWidget);
  });
}
