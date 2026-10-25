import 'dart:io';

import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/category_provider.dart';
import 'package:budget_fuck/providers/template_provider.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_backup_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
    await Hive.openBox<Transaction>('transactions');
    await Hive.openBox<TransactionTemplate>('templates');
    await Hive.openBox<Category>('categories');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('TransactionProvider backup', () {
    late TransactionProvider provider;

    setUp(() => provider = TransactionProvider());

    test('allTransactions returns the transactions of every month', () async {
      await provider.addTransaction(Transaction(
        id: '1',
        amount: 100.0,
        isIncome: true,
        date: DateTime(2026, 1, 1),
        category: 'A',
      ));
      await provider.addTransaction(Transaction(
        id: '2',
        amount: 200.0,
        isIncome: false,
        date: DateTime(2026, 6, 1),
        category: 'B',
      ));
      expect(provider.allTransactions.length, 2);
    });

    test('replaceAll replaces the existing data', () async {
      await provider.addTransaction(Transaction(
        id: 'old',
        amount: 999.0,
        isIncome: false,
        date: DateTime(2026, 1, 1),
        category: 'Vecchio',
      ));
      await provider.replaceAll([
        Transaction(
          id: 'new1',
          amount: 100.0,
          isIncome: true,
          date: DateTime(2026, 6, 1),
          category: 'Nuovo',
        ),
      ]);
      final all = provider.allTransactions;
      expect(all.length, 1);
      expect(all.first.id, 'new1');
    });

    test('replaceAll with an empty list clears the box', () async {
      await provider.addTransaction(Transaction(
        id: '1',
        amount: 50.0,
        isIncome: true,
        date: DateTime(2026, 1, 1),
        category: 'A',
      ));
      await provider.replaceAll([]);
      expect(provider.allTransactions, isEmpty);
    });

    test('addAll only adds missing ids', () async {
      await provider.addTransaction(Transaction(
        id: 'existing',
        amount: 100.0,
        isIncome: true,
        date: DateTime(2026, 1, 1),
        category: 'A',
      ));
      await provider.addAll([
        Transaction(
          id: 'existing',
          amount: 999.0,
          isIncome: false,
          date: DateTime(2026, 1, 1),
          category: 'Modificato',
        ),
        Transaction(
          id: 'new',
          amount: 200.0,
          isIncome: false,
          date: DateTime(2026, 2, 1),
          category: 'Nuovo',
        ),
      ]);
      expect(provider.allTransactions.length, 2);
      final existing =
          provider.allTransactions.firstWhere((t) => t.id == 'existing');
      expect(existing.amount, 100.0);
    });
  });

  group('CategoryProvider backup', () {
    late CategoryProvider provider;

    setUp(() => provider = CategoryProvider());

    test('replaceAll replaces the existing categories', () async {
      await provider.addCategory('Vecchia');
      await provider.replaceAll([Category(id: 'c1', name: 'Nuova')]);
      expect(provider.categories.length, 1);
      expect(provider.categories.first.name, 'Nuova');
    });

    test('replaceAll with an empty list clears the box', () async {
      await provider.addCategory('Alimentari');
      await provider.replaceAll([]);
      expect(provider.categories, isEmpty);
    });

    test('addAll only adds categories with missing ids', () async {
      await provider.addCategory('Alimentari');
      final existingId = provider.categories.first.id;
      await provider.addAll([
        Category(id: existingId, name: 'Modificata'),
        Category(id: 'c_new', name: 'Nuova'),
      ]);
      expect(provider.categories.length, 2);
      final unchanged =
          provider.categories.firstWhere((c) => c.id == existingId);
      expect(unchanged.name, 'Alimentari');
    });
  });

  group('TemplateProvider backup', () {
    late TemplateProvider provider;

    setUp(() => provider = TemplateProvider());

    test('replaceAll replaces the existing templates', () async {
      await provider.addTemplate(TransactionTemplate(
        id: 'old',
        amount: 999.0,
        isIncome: false,
        category: 'Vecchio',
      ));
      await provider.replaceAll([
        TransactionTemplate(
          id: 'new',
          amount: 1500.0,
          isIncome: true,
          category: 'Stipendio',
        ),
      ]);
      expect(provider.templates.length, 1);
      expect(provider.templates.first.id, 'new');
    });

    test('replaceAll with an empty list clears the box', () async {
      await provider.addTemplate(TransactionTemplate(
        id: '1',
        amount: 800.0,
        isIncome: false,
        category: 'Affitto',
      ));
      await provider.replaceAll([]);
      expect(provider.templates, isEmpty);
    });

    test('addAll only adds templates with missing ids', () async {
      await provider.addTemplate(TransactionTemplate(
        id: 'existing',
        amount: 800.0,
        isIncome: false,
        category: 'Affitto',
      ));
      await provider.addAll([
        TransactionTemplate(
          id: 'existing',
          amount: 999.0,
          isIncome: true,
          category: 'Modificato',
        ),
        TransactionTemplate(
          id: 'new',
          amount: 1500.0,
          isIncome: true,
          category: 'Stipendio',
        ),
      ]);
      expect(provider.templates.length, 2);
      final unchanged =
          provider.templates.firstWhere((t) => t.id == 'existing');
      expect(unchanged.amount, 800.0);
    });
  });
}
