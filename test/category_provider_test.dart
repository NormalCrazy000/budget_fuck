import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/providers/category_provider.dart';

/// Test unitari per [CategoryProvider].
///
/// Verificano il corretto funzionamento di:
/// - Aggiunta e rimozione categorie (CRUD)
/// - Ordinamento alfabetico (case-insensitive)
/// - Validazione duplicati (case-insensitive, con trim spazi)
/// - Generazione id univoci
///
/// Ogni test usa una directory temporanea per Hive, che viene
/// cancellata nel tearDown per garantire isolamento tra i test.
void main() {
  late CategoryProvider provider;
  late Directory tempDir;

  // Crea un ambiente Hive isolato prima di ogni test
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CategoryAdapter());
    }
    await Hive.openBox<Category>('categories');
    provider = CategoryProvider();
  });

  // Chiude Hive e rimuove i file temporanei dopo ogni test
  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('inizialmente la lista è vuota', () {
    expect(provider.categories, isEmpty);
  });

  test('addCategory aggiunge una categoria', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categories.length, 1);
    expect(provider.categories.first.name, 'Alimentari');
  });

  test('addCategory fa trim del nome', () async {
    await provider.addCategory('  Trasporti  ');
    expect(provider.categories.first.name, 'Trasporti');
  });

  test('deleteCategory rimuove una categoria', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categories.length, 1);

    final id = provider.categories.first.id;
    await provider.deleteCategory(id);
    expect(provider.categories, isEmpty);
  });

  // I Future.delayed servono per garantire id univoci basati su
  // DateTime.now().millisecondsSinceEpoch tra chiamate consecutive rapide
  test('categories sono ordinate alfabeticamente', () async {
    await provider.addCategory('Trasporti');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Bollette');

    final names = provider.categories.map((c) => c.name).toList();
    expect(names, ['Alimentari', 'Bollette', 'Trasporti']);
  });

  test('ordinamento è case-insensitive', () async {
    await provider.addCategory('bollette');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('trasporti');

    final names = provider.categories.map((c) => c.name).toList();
    expect(names, ['Alimentari', 'bollette', 'trasporti']);
  });

  test('categoryExists rileva duplicato esatto', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('Alimentari'), isTrue);
    expect(provider.categoryExists('Trasporti'), isFalse);
  });

  test('categoryExists è case-insensitive', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('alimentari'), isTrue);
    expect(provider.categoryExists('ALIMENTARI'), isTrue);
  });

  test('categoryExists gestisce spazi', () async {
    await provider.addCategory('Alimentari');
    expect(provider.categoryExists('  Alimentari  '), isTrue);
  });

  test('deleteCategory con id inesistente non fa nulla', () async {
    await provider.addCategory('Alimentari');
    await provider.deleteCategory('id_inesistente');
    expect(provider.categories.length, 1);
  });

  test('più categorie con id univoci', () async {
    await provider.addCategory('Alimentari');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Trasporti');
    await Future.delayed(const Duration(milliseconds: 2));
    await provider.addCategory('Bollette');
    expect(provider.categories.length, 3);

    // Verifica che tutti gli id siano distinti
    final ids = provider.categories.map((c) => c.id).toSet();
    expect(ids.length, 3);
  });
}
