import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'package:budget_fuck/screens/stats_screen.dart';

/// Fake TransactionProvider che non dipende da Hive.
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
    await initializeDateFormatting('it', null);
  });

  setUp(() {
    provider = FakeTransactionProvider();
  });

  Widget buildWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<TransactionProvider>.value(
        value: provider,
        child: const StatsScreen(),
      ),
    );
  }

  testWidgets('mostra due tab Uscite ed Entrate', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Uscite'), findsOneWidget);
    expect(find.text('Entrate'), findsOneWidget);
  });

  testWidgets('tab Uscite vuoto mostra messaggio', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Nessuna uscita questo mese'), findsOneWidget);
  });

  testWidgets('tab Entrate vuoto mostra messaggio', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Entrate'));
    await tester.pumpAndSettle();

    expect(find.text('Nessuna entrata questo mese'), findsOneWidget);
  });

  testWidgets('mostra categoria con importo corretto', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 50.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Alimentari'), findsOneWidget);
    // il formato it_IT è "50,00 €"
    expect(find.textContaining('50,00'), findsWidgets);
  });

  testWidgets('aggrega più transazioni della stessa categoria', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 30.0, isIncome: false, category: 'Alimentari'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 20.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // 30 + 20 = 50 come totale categoria
    expect(find.textContaining('50,00'), findsWidgets);
    // due transazioni
    expect(find.text('2 transazioni'), findsOneWidget);
  });

  testWidgets('ordina categorie per importo decrescente', (tester) async {
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

  testWidgets('mostra 100% per categoria unica', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 100.0, isIncome: false, category: 'Alimentari'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('100.0%'), findsOneWidget);
  });

  testWidgets('calcola percentuale corretta con due categorie', (tester) async {
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

  testWidgets('entrate e uscite sono nei tab separati', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 100.0, isIncome: false, category: 'Spesa'),
    );
    await provider.addTransaction(
      _tx(id: '2', amount: 200.0, isIncome: true, category: 'Stipendio'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Tab Uscite: vede Spesa, non Stipendio
    expect(find.text('Spesa'), findsOneWidget);
    expect(find.text('Stipendio'), findsNothing);

    // Passa a tab Entrate
    await tester.tap(find.text('Entrate'));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Spesa'), findsNothing);
  });

  testWidgets('freccia sinistra va al mese precedente', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('MAGGIO 2026'), findsOneWidget);
  });

  testWidgets('freccia destra va al mese successivo', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('LUGLIO 2026'), findsOneWidget);
  });

  testWidgets('transazioni di altri mesi non compaiono', (tester) async {
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

    // Il provider è su giugno 2026, la transazione è di maggio
    expect(find.text('Nessuna uscita questo mese'), findsOneWidget);
  });

  testWidgets('singola transazione mostra testo al singolare', (tester) async {
    await provider.addTransaction(
      _tx(id: '1', amount: 10.0, isIncome: false, category: 'Altro'),
    );
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('1 transazione'), findsOneWidget);
  });
}
