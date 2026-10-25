import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/category_provider.dart';
import 'package:budget_fuck/providers/template_provider.dart';
import 'package:budget_fuck/providers/transaction_provider.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:budget_fuck/screens/backup_screen.dart';
import 'package:budget_fuck/services/backup_service.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeTransactionProvider extends ChangeNotifier
    implements TransactionProvider {
  final List<Transaction> _all = [];

  @override
  List<Transaction> get allTransactions => List.unmodifiable(_all);

  @override
  List<Transaction> get transactions => _all;

  @override
  int get selectedMonth => DateTime.now().month;

  @override
  int get selectedYear => DateTime.now().year;

  @override
  double get totalIncome => 0;

  @override
  double get totalExpense => 0;

  @override
  double get balance => 0;

  @override
  void previousMonth() {}

  @override
  void nextMonth() {}

  @override
  void setMonth(int month, int year) {}

  @override
  Future<void> addTransaction(Transaction t) async => _all.add(t);

  @override
  Future<void> deleteTransaction(String id) async =>
      _all.removeWhere((t) => t.id == id);

  @override
  Future<void> replaceAll(List<Transaction> transactions) async {
    _all
      ..clear()
      ..addAll(transactions);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<Transaction> transactions) async {
    final ids = _all.map((t) => t.id).toSet();
    _all.addAll(transactions.where((t) => !ids.contains(t.id)));
    notifyListeners();
  }
}

class _FakeCategoryProvider extends ChangeNotifier implements CategoryProvider {
  final List<Category> _cats = [];

  @override
  List<Category> get categories => List.unmodifiable(_cats);

  @override
  Future<void> addCategory(String name) async {}

  @override
  Future<void> deleteCategory(String id) async {}

  @override
  bool categoryExists(String name) => false;

  @override
  Future<void> replaceAll(List<Category> cats) async {
    _cats
      ..clear()
      ..addAll(cats);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<Category> cats) async {
    final ids = _cats.map((c) => c.id).toSet();
    _cats.addAll(cats.where((c) => !ids.contains(c.id)));
    notifyListeners();
  }
}

class _FakeTemplateProvider extends ChangeNotifier implements TemplateProvider {
  final List<TransactionTemplate> _tmpls = [];

  @override
  List<TransactionTemplate> get templates => List.unmodifiable(_tmpls);

  @override
  List<TransactionTemplate> get incomeTemplates =>
      _tmpls.where((t) => t.isIncome).toList();

  @override
  List<TransactionTemplate> get expenseTemplates =>
      _tmpls.where((t) => !t.isIncome).toList();

  @override
  Future<void> addTemplate(TransactionTemplate t) async => _tmpls.add(t);

  @override
  Future<void> deleteTemplate(String id) async =>
      _tmpls.removeWhere((t) => t.id == id);

  @override
  Future<void> replaceAll(List<TransactionTemplate> tmpls) async {
    _tmpls
      ..clear()
      ..addAll(tmpls);
    notifyListeners();
  }

  @override
  Future<void> addAll(List<TransactionTemplate> tmpls) async {
    final ids = _tmpls.map((t) => t.id).toSet();
    _tmpls.addAll(tmpls.where((t) => !ids.contains(t.id)));
    notifyListeners();
  }
}

/// Finestra "Salva come" finta: registra cosa riceve e restituisce [result]
/// (null simula l'utente che chiude la finestra senza salvare).
class _FakeSaveDialog {
  _FakeSaveDialog({this.result});

  final Uri? result;
  String? fileName;
  Uint8List? bytes;
  String? mimeType;
  int calls = 0;

  Future<Uri?> call({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'application/octet-stream',
    String? dialogTitle,
  }) async {
    calls++;
    this.fileName = fileName;
    this.bytes = bytes;
    this.mimeType = mimeType;
    return result;
  }
}

Widget _buildWidget({_FakeSaveDialog? saveDialog}) {
  final dialog = saveDialog ?? _FakeSaveDialog();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<TransactionProvider>.value(
        value: _FakeTransactionProvider(),
      ),
      ChangeNotifierProvider<CategoryProvider>.value(
        value: _FakeCategoryProvider(),
      ),
      ChangeNotifierProvider<TemplateProvider>.value(
        value: _FakeTemplateProvider(),
      ),
    ],
    child: MaterialApp(home: BackupScreen(saveFileDialog: dialog.call)),
  );
}

void main() {
  testWidgets('mostra il titolo Backup & Ripristino', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Backup & Ripristino'), findsOneWidget);
  });

  testWidgets('mostra il pulsante Salva su file', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Salva su file'), findsOneWidget);
  });

  testWidgets('su telefono mostra anche il pulsante Condividi',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Condividi'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('su desktop nasconde il pulsante Condividi', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Condividi'), findsNothing);
    expect(find.text('Salva su file'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Salva su file passa alla finestra un backup JSON valido',
      (tester) async {
    final dialog = _FakeSaveDialog(
      result: Uri.file('/tmp/budget_backup.json'),
    );
    await tester.pumpWidget(_buildWidget(saveDialog: dialog));

    await tester.tap(find.text('Salva su file'));
    await tester.pumpAndSettle();

    expect(dialog.calls, 1);
    expect(dialog.fileName, matches(RegExp(r'^budget_backup_\d{8}\.json$')));
    expect(dialog.mimeType, 'application/json');
    // Il contenuto deve essere un backup reimportabile
    final data = BackupService.parseJson(utf8.decode(dialog.bytes!));
    expect(data.transactions, isEmpty);
    expect(find.textContaining('Backup salvato'), findsOneWidget);
  });

  testWidgets('se si annulla la finestra non mostra messaggi',
      (tester) async {
    final dialog = _FakeSaveDialog(result: null);
    await tester.pumpWidget(_buildWidget(saveDialog: dialog));

    await tester.tap(find.text('Salva su file'));
    await tester.pumpAndSettle();

    expect(dialog.calls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('mostra il pulsante Importa backup', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Importa backup'), findsOneWidget);
  });

  testWidgets('mostra il testo descrittivo', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(
      find.textContaining('Esporta tutti i dati'),
      findsOneWidget,
    );
  });

  testWidgets('non solleva eccezioni Flutter al rendering', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(tester.takeException(), isNull);
  });
}
