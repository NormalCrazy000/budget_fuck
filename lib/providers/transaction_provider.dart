import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction.dart';

/// Provider centrale per la gestione delle transazioni.
///
/// Gestisce lo stato dell'app tramite [ChangeNotifier]:
/// - CRUD delle transazioni (add/delete) con persistenza su Hive
/// - Filtro per mese/anno con navigazione avanti/indietro
/// - Proprietà calcolate per totali entrate, uscite e bilancio
///
/// Viene iniettato nell'albero dei widget tramite [ChangeNotifierProvider]
/// e i widget lo consumano con `context.watch` o `context.read`.
class TransactionProvider extends ChangeNotifier {
  static const String _boxName = 'transactions';
  late Box<Transaction> _box;

  /// Mese e anno attualmente selezionati per il filtro
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  TransactionProvider() {
    // Recupera il box già aperto in main.dart
    _box = Hive.box<Transaction>(_boxName);
  }

  /// Restituisce le transazioni filtrate per il mese/anno selezionato,
  /// ordinate dalla più recente alla più vecchia.
  List<Transaction> get transactions {
    return _box.values.where((t) {
      return t.date.month == _selectedMonth && t.date.year == _selectedYear;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Somma di tutte le entrate del mese selezionato.
  double get totalIncome {
    return transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Somma di tutte le uscite del mese selezionato.
  double get totalExpense {
    return transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Bilancio netto: entrate - uscite. Può essere negativo.
  double get balance => totalIncome - totalExpense;

  /// Imposta direttamente mese e anno per il filtro.
  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    notifyListeners();
  }

  /// Naviga al mese precedente. Gestisce il passaggio dicembre -> gennaio.
  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    notifyListeners();
  }

  /// Naviga al mese successivo. Gestisce il passaggio dicembre -> gennaio.
  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    notifyListeners();
  }

  /// Salva una nuova transazione nel database locale.
  /// Usa l'id come chiave per permettere accesso diretto.
  Future<void> addTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    notifyListeners();
  }

  /// Elimina una transazione dal database tramite il suo id.
  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
    notifyListeners();
  }
}
