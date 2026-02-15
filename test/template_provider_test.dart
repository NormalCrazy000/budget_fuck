import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/template_provider.dart';

void main() {
  late TemplateProvider provider;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    await Hive.openBox<TransactionTemplate>('templates');
    provider = TemplateProvider();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('addTemplate aggiunge un template', () async {
    final template = TransactionTemplate(
      id: '1',
      amount: 2000,
      isIncome: true,
      category: 'Lavoro',
    );
    await provider.addTemplate(template);
    expect(provider.templates.length, 1);
    expect(provider.templates.first.category, 'Lavoro');
  });

  test('deleteTemplate rimuove un template', () async {
    final template = TransactionTemplate(
      id: '1',
      amount: 800,
      isIncome: false,
      category: 'Casa',
    );
    await provider.addTemplate(template);
    expect(provider.templates.length, 1);

    await provider.deleteTemplate('1');
    expect(provider.templates.length, 0);
  });

  test('incomeTemplates filtra solo entrate', () async {
    await provider.addTemplate(TransactionTemplate(
      id: '1',
      amount: 2000,
      isIncome: true,
      category: 'Lavoro',
    ));
    await provider.addTemplate(TransactionTemplate(
      id: '2',
      amount: 800,
      isIncome: false,
      category: 'Casa',
    ));
    await provider.addTemplate(TransactionTemplate(
      id: '3',
      amount: 500,
      isIncome: true,
      category: 'Freelance',
    ));

    expect(provider.incomeTemplates.length, 2);
    expect(provider.expenseTemplates.length, 1);
    expect(provider.templates.length, 3);
  });

  test('expenseTemplates filtra solo uscite', () async {
    await provider.addTemplate(TransactionTemplate(
      id: '1',
      amount: 2000,
      isIncome: true,
      category: 'Lavoro',
    ));
    await provider.addTemplate(TransactionTemplate(
      id: '2',
      amount: 800,
      isIncome: false,
      category: 'Casa',
    ));

    expect(provider.expenseTemplates.length, 1);
    expect(provider.expenseTemplates.first.category, 'Casa');
  });
}
