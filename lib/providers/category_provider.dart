// hide Category per evitare conflitto con l'omonima classe di Flutter
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import '../models/category.dart';

/// Provider per la gestione delle categorie di transazione.
///
/// Gestisce lo stato delle categorie tramite [ChangeNotifier]:
/// - CRUD delle categorie (add/delete) con persistenza su Hive
/// - Getter con ordinamento alfabetico
/// - Validazione duplicati (case-insensitive)
///
/// Viene iniettato nell'albero dei widget tramite [MultiProvider]
/// e i widget lo consumano con `context.watch` o `context.read`.
class CategoryProvider extends ChangeNotifier {
  static const String _boxName = 'categories';
  late Box<Category> _box;

  CategoryProvider() {
    // Recupera il box già aperto in main.dart
    _box = Hive.box<Category>(_boxName);
  }

  /// Restituisce tutte le categorie ordinate alfabeticamente (case-insensitive).
  List<Category> get categories {
    final list = _box.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Crea e salva una nuova categoria nel database locale.
  /// Il nome viene trimmato prima del salvataggio.
  /// L'id viene generato dal timestamp corrente in millisecondi.
  Future<void> addCategory(String name) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    await _box.put(category.id, category);
    notifyListeners();
  }

  /// Elimina una categoria dal database tramite il suo id.
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Verifica se esiste già una categoria con lo stesso nome.
  /// Il confronto è case-insensitive e ignora spazi iniziali/finali.
  bool categoryExists(String name) {
    return _box.values.any(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  /// Sostituisce tutti i dati con la lista fornita (usato dall'import backup).
  Future<void> replaceAll(List<Category> cats) async {
    await _box.clear();
    for (final c in cats) {
      await _box.put(c.id, c);
    }
    notifyListeners();
  }

  /// Aggiunge le categorie mancanti senza toccare quelle esistenti.
  Future<void> addAll(List<Category> cats) async {
    for (final c in cats) {
      if (!_box.containsKey(c.id)) {
        await _box.put(c.id, c);
      }
    }
    notifyListeners();
  }
}
