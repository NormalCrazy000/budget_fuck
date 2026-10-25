import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction_template.dart';

/// Provider that manages the predefined transaction templates.
///
/// Holds the template state via [ChangeNotifier]:
/// - add/delete with Hive persistence
/// - getters filtered by type (income/expense)
///
/// Injected into the widget tree via [MultiProvider]; widgets consume it
/// with `context.watch` or `context.read`.
class TemplateProvider extends ChangeNotifier {
  static const String _boxName = 'templates';
  late Box<TransactionTemplate> _box;

  TemplateProvider() {
    // Gets the box already opened in main.dart
    _box = Hive.box<TransactionTemplate>(_boxName);
  }

  /// All saved templates.
  List<TransactionTemplate> get templates {
    return _box.values.toList();
  }

  /// Income templates only.
  List<TransactionTemplate> get incomeTemplates {
    return _box.values.where((t) => t.isIncome).toList();
  }

  /// Expense templates only.
  List<TransactionTemplate> get expenseTemplates {
    return _box.values.where((t) => !t.isIncome).toList();
  }

  /// Saves a new template in the local database.
  /// The id is used as the key for direct access.
  Future<void> addTemplate(TransactionTemplate template) async {
    await _box.put(template.id, template);
    notifyListeners();
  }

  /// Deletes a template from the database by its id.
  Future<void> deleteTemplate(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Replaces all data with the given list (used by backup import).
  Future<void> replaceAll(List<TransactionTemplate> tmpls) async {
    await _box.clear();
    for (final t in tmpls) {
      await _box.put(t.id, t);
    }
    notifyListeners();
  }

  /// Adds the missing templates without touching the existing ones.
  Future<void> addAll(List<TransactionTemplate> tmpls) async {
    for (final t in tmpls) {
      if (!_box.containsKey(t.id)) {
        await _box.put(t.id, t);
      }
    }
    notifyListeners();
  }
}
