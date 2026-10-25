import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

/// Main provider for transactions.
///
/// Holds the app state via [ChangeNotifier]:
/// - add/delete with Hive persistence
/// - month/year filter with previous/next navigation
/// - computed totals for income, expenses and balance
///
/// Injected into the widget tree via [ChangeNotifierProvider]; widgets
/// consume it with `context.watch` or `context.read`.
class TransactionProvider extends ChangeNotifier {
  static const String _boxName = 'transactions';
  late Box<Transaction> _box;

  /// Month and year currently selected for the filter
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  TransactionProvider() {
    // Gets the box already opened in main.dart
    _box = Hive.box<Transaction>(_boxName);
  }

  /// Transactions of the selected month/year, newest first.
  List<Transaction> get transactions {
    return _box.values.where((t) {
      return t.date.month == _selectedMonth && t.date.year == _selectedYear;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Sum of all income in the selected month.
  double get totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Sum of all expenses in the selected month.
  double get totalExpense {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Net balance: income - expenses. Can be negative.
  double get balance => totalIncome - totalExpense;

  /// Sets the filter month and year directly.
  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  /// Goes to the previous month, handling the January -> December rollover.
  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    notifyListeners();
  }

  /// Goes to the next month, handling the December -> January rollover.
  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    notifyListeners();
  }

  /// Saves a new transaction in the local database.
  /// The id is used as the key for direct access.
  Future<void> addTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    notifyListeners();
  }

  /// Deletes a transaction from the database by its id.
  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// All transactions (every month), used by the backup.
  List<Transaction> get allTransactions => _box.values.toList();

  /// Replaces all data with the given list (used by backup import).
  Future<void> replaceAll(List<Transaction> transactions) async {
    await _box.clear();
    for (final t in transactions) {
      await _box.put(t.id, t);
    }
    notifyListeners();
  }

  /// Adds the missing transactions without touching the existing ones.
  Future<void> addAll(List<Transaction> transactions) async {
    for (final t in transactions) {
      if (!_box.containsKey(t.id)) {
        await _box.put(t.id, t);
      }
    }
    notifyListeners();
  }
}
