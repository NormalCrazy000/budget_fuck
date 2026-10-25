import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/providers/category_provider.dart';

/// Unit tests for [CategoryProvider].
///
/// They check:
/// - adding and removing categories
/// - alphabetical sorting (case-insensitive)
/// - duplicate check (case-insensitive, trimming spaces)
/// - unique id generation
///
/// Each test uses a temporary Hive directory, deleted in tearDown
/// so tests stay isolated from each other.
void main() {
  late CategoryProvider provider;
  late Directory tempDir;

  // Create an isolated Hive environment before each test
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    await Hive.openBox<Category>('categories');
    provider = CategoryProvider();
  });

  // Close Hive and remove the temporary files after each test
  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('the list is initially empty', () {
    expect(provider.categories, isEmpty);
  });

  test('addCategory adds a category', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categories.length, 1);
    expect(provider.categories.first.name, 'Alimentari');
  });

  test('addCategory trims the name', () async {
    await provider.addCategory('  Trasporti  ');
    expect(provider.categories.first.name, 'Trasporti');
  });

  test('deleteCategory removes a category', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categories.length, 1);

    final id = provider.categories.first.id;
    await provider.deleteCategory(id);
    expect(provider.categories, isEmpty);
  });

  // The Future.delayed calls guarantee unique ids based on
  // DateTime.now().millisecondsSinceEpoch across quick consecutive calls
  test('categories are sorted alphabetically', () async {
    await provider.addCategory('Trasporti');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Bollette');

    final names = provider.categories.map((c) => c.name).toList();
    expect(names, ['Alimentari', 'Bollette', 'Trasporti']);
  });

  test('sorting is case-insensitive', () async {
    await provider.addCategory('bollette');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('trasporti');

    final names = provider.categories.map((c) => c.name).toList();
    expect(names, ['Alimentari', 'bollette', 'trasporti']);
  });

  test('categoryExists detects an exact duplicate', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('Alimentari'), isTrue);
    expect(provider.categoryExists('Trasporti'), isFalse);
  });

  test('categoryExists is case-insensitive', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('alimentari'), isTrue);
    expect(provider.categoryExists('ALIMENTARI'), isTrue);
  });

  test('categoryExists handles spaces', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('  Alimentari  '), isTrue);
  });

  test('deleteCategory with an unknown id does nothing', () async {
    await provider.addCategory('Alimentari');
    await provider.deleteCategory('id_inesistente');
    expect(provider.categories.length, 1);
  });

  test('multiple categories get unique ids', () async {
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Trasporti');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Bollette');
    expect(provider.categories.length, 3);

    // Check that all ids are distinct
    final ids = provider.categories.map((c) => c.id).toSet();
    expect(ids.length, 3);
  });
}
