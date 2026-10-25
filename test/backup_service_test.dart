import 'dart:convert';

import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupService.exportToJson', () {
    test('produces valid JSON', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [],
        templates: [],
      );
      expect(() => jsonDecode(json), returnsNormally);
    });

    test('includes version and exportDate', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [],
        templates: [],
      );
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect(data['version'], 1);
      expect(data['exportDate'], isA<String>());
    });

    test('serializes a transaction with all fields', () {
      final date = DateTime(2026, 6, 14, 10, 30);
      final json = BackupService.exportToJson(
        transactions: [
          Transaction(
            id: '1',
            amount: 50.0,
            isIncome: true,
            date: date,
            category: 'Lavoro',
          ),
        ],
        categories: [],
        templates: [],
      );
      final txJson = (jsonDecode(json)['transactions'] as List).first
          as Map<String, dynamic>;
      expect(txJson['id'], '1');
      expect(txJson['amount'], 50.0);
      expect(txJson['isIncome'], true);
      expect(txJson['date'], date.toIso8601String());
      expect(txJson['category'], 'Lavoro');
    });

    test('serializes a category with all fields', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [Category(id: 'c1', name: 'Alimentari')],
        templates: [],
      );
      final catJson = (jsonDecode(json)['categories'] as List).first
          as Map<String, dynamic>;
      expect(catJson['id'], 'c1');
      expect(catJson['name'], 'Alimentari');
    });

    test('serializes a template with all fields', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [],
        templates: [
          TransactionTemplate(
            id: 't1',
            amount: 800.0,
            isIncome: false,
            category: 'Affitto',
          ),
        ],
      );
      final tmplJson = (jsonDecode(json)['templates'] as List).first
          as Map<String, dynamic>;
      expect(tmplJson['id'], 't1');
      expect(tmplJson['amount'], 800.0);
      expect(tmplJson['isIncome'], false);
      expect(tmplJson['category'], 'Affitto');
    });

    test('serializes multiple items correctly', () {
      final json = BackupService.exportToJson(
        transactions: [
          Transaction(
            id: '1',
            amount: 100.0,
            isIncome: true,
            date: DateTime(2026, 1, 1),
            category: 'A',
          ),
          Transaction(
            id: '2',
            amount: 200.0,
            isIncome: false,
            date: DateTime(2026, 1, 2),
            category: 'B',
          ),
        ],
        categories: [
          Category(id: 'c1', name: 'A'),
          Category(id: 'c2', name: 'B'),
        ],
        templates: [
          TransactionTemplate(
            id: 't1',
            amount: 500.0,
            isIncome: true,
            category: 'A',
          ),
        ],
      );
      final data = jsonDecode(json) as Map<String, dynamic>;
      expect((data['transactions'] as List).length, 2);
      expect((data['categories'] as List).length, 2);
      expect((data['templates'] as List).length, 1);
    });
  });

  group('BackupService.parseJson', () {
    test('transaction round-trip keeps all fields', () {
      final date = DateTime(2026, 6, 14, 10, 30);
      final json = BackupService.exportToJson(
        transactions: [
          Transaction(
            id: '1',
            amount: 123.45,
            isIncome: false,
            date: date,
            category: 'Bollette',
          ),
        ],
        categories: [],
        templates: [],
      );
      final t = BackupService.parseJson(json).transactions.first;
      expect(t.id, '1');
      expect(t.amount, 123.45);
      expect(t.isIncome, false);
      expect(t.date, date);
      expect(t.category, 'Bollette');
    });

    test('category round-trip keeps all fields', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [Category(id: 'c1', name: 'Salute')],
        templates: [],
      );
      final c = BackupService.parseJson(json).categories.first;
      expect(c.id, 'c1');
      expect(c.name, 'Salute');
    });

    test('template round-trip keeps all fields', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [],
        templates: [
          TransactionTemplate(
            id: 't1',
            amount: 2000.0,
            isIncome: true,
            category: 'Stipendio',
          ),
        ],
      );
      final t = BackupService.parseJson(json).templates.first;
      expect(t.id, 't1');
      expect(t.amount, 2000.0);
      expect(t.isIncome, true);
      expect(t.category, 'Stipendio');
    });

    test('handles amount as an integer in the JSON', () {
      const json = '''
{
  "version": 1,
  "exportDate": "2026-06-14T00:00:00.000",
  "transactions": [{"id":"1","amount":50,"isIncome":true,"date":"2026-06-14T00:00:00.000","category":"Lavoro"}],
  "categories": [],
  "templates": []
}''';
      expect(BackupService.parseJson(json).transactions.first.amount, 50.0);
    });

    test('empty backup returns empty lists', () {
      final json = BackupService.exportToJson(
        transactions: [],
        categories: [],
        templates: [],
      );
      final data = BackupService.parseJson(json);
      expect(data.transactions, isEmpty);
      expect(data.categories, isEmpty);
      expect(data.templates, isEmpty);
    });

    test('throws on invalid JSON', () {
      expect(
        () => BackupService.parseJson('non è json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('full round-trip with multiple items', () {
      final json = BackupService.exportToJson(
        transactions: [
          Transaction(
            id: '1',
            amount: 1500.0,
            isIncome: true,
            date: DateTime(2026, 1, 1),
            category: 'Stipendio',
          ),
          Transaction(
            id: '2',
            amount: 50.0,
            isIncome: false,
            date: DateTime(2026, 1, 15),
            category: 'Spesa',
          ),
        ],
        categories: [
          Category(id: 'c1', name: 'Stipendio'),
          Category(id: 'c2', name: 'Spesa'),
        ],
        templates: [
          TransactionTemplate(
            id: 't1',
            amount: 1500.0,
            isIncome: true,
            category: 'Stipendio',
          ),
        ],
      );
      final data = BackupService.parseJson(json);
      expect(data.transactions.length, 2);
      expect(data.categories.length, 2);
      expect(data.templates.length, 1);
    });
  });
}
