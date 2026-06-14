import 'dart:convert';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_template.dart';

class BackupData {
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<TransactionTemplate> templates;

  const BackupData({
    required this.transactions,
    required this.categories,
    required this.templates,
  });
}

class BackupService {
  static String exportToJson({
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<TransactionTemplate> templates,
  }) {
    return const JsonEncoder.withIndent('  ').convert({
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'transactions': transactions
          .map((t) => {
                'id': t.id,
                'amount': t.amount,
                'isIncome': t.isIncome,
                'date': t.date.toIso8601String(),
                'category': t.category,
              })
          .toList(),
      'categories': categories
          .map((c) => {
                'id': c.id,
                'name': c.name,
              })
          .toList(),
      'templates': templates
          .map((t) => {
                'id': t.id,
                'amount': t.amount,
                'isIncome': t.isIncome,
                'category': t.category,
              })
          .toList(),
    });
  }

  static BackupData parseJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;

    final transactions = (data['transactions'] as List)
        .map((t) => Transaction(
              id: t['id'] as String,
              amount: (t['amount'] as num).toDouble(),
              isIncome: t['isIncome'] as bool,
              date: DateTime.parse(t['date'] as String),
              category: t['category'] as String,
            ))
        .toList();

    final categories = (data['categories'] as List)
        .map((c) => Category(
              id: c['id'] as String,
              name: c['name'] as String,
            ))
        .toList();

    final templates = (data['templates'] as List)
        .map((t) => TransactionTemplate(
              id: t['id'] as String,
              amount: (t['amount'] as num).toDouble(),
              isIncome: t['isIncome'] as bool,
              category: t['category'] as String,
            ))
        .toList();

    return BackupData(
      transactions: transactions,
      categories: categories,
      templates: templates,
    );
  }
}
