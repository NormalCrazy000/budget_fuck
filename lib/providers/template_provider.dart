import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction_template.dart';

/// Provider per la gestione dei template di transazione predefiniti.
///
/// Gestisce lo stato dei template tramite [ChangeNotifier]:
/// - CRUD dei template (add/delete) con persistenza su Hive
/// - Getter filtrati per tipo (entrate/uscite)
///
/// Viene iniettato nell'albero dei widget tramite [MultiProvider]
/// e i widget lo consumano con `context.watch` o `context.read`.
class TemplateProvider extends ChangeNotifier {
  static const String _boxName = 'templates';
  late Box<TransactionTemplate> _box;

  TemplateProvider() {
    // Recupera il box già aperto in main.dart
    _box = Hive.box<TransactionTemplate>(_boxName);
  }

  /// Restituisce tutti i template salvati.
  List<TransactionTemplate> get templates {
    return _box.values.toList();
  }

  /// Restituisce solo i template di tipo entrata.
  List<TransactionTemplate> get incomeTemplates {
    return _box.values.where((t) => t.isIncome).toList();
  }

  /// Restituisce solo i template di tipo uscita.
  List<TransactionTemplate> get expenseTemplates {
    return _box.values.where((t) => !t.isIncome).toList();
  }

  /// Salva un nuovo template nel database locale.
  /// Usa l'id come chiave per permettere accesso diretto.
  Future<void> addTemplate(TransactionTemplate template) async {
    await _box.put(template.id, template);
    notifyListeners();
  }

  /// Elimina un template dal database tramite il suo id.
  Future<void> deleteTemplate(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Sostituisce tutti i dati con la lista fornita (usato dall'import backup).
  Future<void> replaceAll(List<TransactionTemplate> tmpls) async {
    await _box.clear();
    for (final t in tmpls) {
      await _box.put(t.id, t);
    }
    notifyListeners();
  }

  /// Aggiunge i template mancanti senza toccare quelli esistenti.
  Future<void> addAll(List<TransactionTemplate> tmpls) async {
    for (final t in tmpls) {
      if (!_box.containsKey(t.id)) {
        await _box.put(t.id, t);
      }
    }
    notifyListeners();
  }
}
