import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'package:budget_fuck/screens/home_screen.dart';

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

Transaction _tx(String id, String category, double amount,
    {bool isIncome = false}) {
  return Transaction(
    id: id,
    amount: amount,
    isIncome: isIncome,
    category: category,
    date: DateTime(2026, 6, 10),
  );
}

void main() {
  late FakeTransactionProvider provider;

  setUpAll(() async {
    await initializeDateFormatting('it', null);
  });

  setUp(() async {
    provider = FakeTransactionProvider(month: 6, year: 2026);
    await provider.addAll([
      _tx('1', 'Stipendio', 2000, isIncome: true),
      _tx('2', 'Affitto', 800),
      _tx('3', 'Spesa', 150),
    ]);
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const HomeScreen(),
      ),
    );
  }

  final searchField = find.widgetWithText(TextField, 'Cerca per categoria');

  testWidgets('search filters transactions by category',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'aff');
    await tester.pumpAndSettle();

    expect(find.text('Affitto'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);
    expect(find.text('Spesa'), findsNothing);
  });

  testWidgets('totals still cover the whole month while searching',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'aff');
    await tester.pumpAndSettle();

    // Income 2000, expenses 800 + 150 = 950, balance 1050
    expect(find.textContaining('2.000,00'), findsOneWidget);
    expect(find.textContaining('950,00'), findsOneWidget);
    expect(find.textContaining('1.050,00'), findsOneWidget);
  });

  testWidgets('shows "Nessun risultato" when the search finds nothing',
      (tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.enterText(searchField, 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('Nessun risultato'), findsOneWidget);
    expect(find.text('Nessuna transazione questo mese'), findsNothing);
  });
}
