// hide Category to avoid a clash with Flutter's class of the same name
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import '../models/category.dart';

/// Provider that manages transaction categories.
///
/// Holds the category state via [ChangeNotifier]:
/// - add/delete with Hive persistence
/// - getter sorted alphabetically
/// - duplicate check (case-insensitive)
///
/// Injected into the widget tree via [MultiProvider]; widgets consume it
/// with `context.watch` or `context.read`.
class CategoryProvider extends ChangeNotifier {
  static const String _boxName = 'categories';
  late Box<Category> _box;

  CategoryProvider() {
    // Gets the box already opened in main.dart
    _box = Hive.box<Category>(_boxName);
  }

  /// All categories sorted alphabetically (case-insensitive).
  List<Category> get categories {
    final list = _box.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  /// Creates and saves a new category in the local database.
  /// The name is trimmed before saving.
  /// The id is the current timestamp in milliseconds.
  Future<void> addCategory(String name) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    await _box.put(category.id, category);
    notifyListeners();
  }

  /// Deletes a category from the database by its id.
  Future<void> deleteCategory(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Whether a category with the same name already exists.
  /// The comparison is case-insensitive and ignores leading/trailing spaces.
  bool categoryExists(String name) {
    return _box.values.any(
      (c) => c.name.toLowerCase() == name.trim().toLowerCase(),
    );
  }

  /// Replaces all data with the given list (used by backup import).
  Future<void> replaceAll(List<Category> cats) async {
    await _box.clear();
    for (final c in cats) {
      await _box.put(c.id, c);
    }
    notifyListeners();
  }

  /// Adds the missing categories without touching the existing ones.
  Future<void> addAll(List<Category> cats) async {
    for (final c in cats) {
      if (!_box.containsKey(c.id)) {
        await _box.put(c.id, c);
      }
    }
    notifyListeners();
  }
}
