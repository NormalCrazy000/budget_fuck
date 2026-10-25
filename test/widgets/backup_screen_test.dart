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

import '../helpers/localized_app.dart';

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

/// Fake "Save as" dialog: records what it receives and returns [result]
/// (null simulates the user closing the dialog without saving).
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
    child: localizedApp(home: BackupScreen(saveFileDialog: dialog.call)),
  );
}

void main() {
  testWidgets('shows the Backup & restore title', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Backup & restore'), findsOneWidget);
  });

  testWidgets('shows the Save to file button', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Save to file'), findsOneWidget);
  });

  testWidgets('on phones also shows the Share button',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Share'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('on desktop hides the Share button', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Share'), findsNothing);
    expect(find.text('Save to file'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Save to file passes a valid JSON backup to the dialog',
      (tester) async {
    final dialog = _FakeSaveDialog(
      result: Uri.file('/tmp/budget_backup.json'),
    );
    await tester.pumpWidget(_buildWidget(saveDialog: dialog));

    await tester.tap(find.text('Save to file'));
    await tester.pumpAndSettle();

    expect(dialog.calls, 1);
    expect(dialog.fileName, matches(RegExp(r'^budget_backup_\d{8}\.json$')));
    expect(dialog.mimeType, 'application/json');
    // The content must be a backup that can be imported again
    final data = BackupService.parseJson(utf8.decode(dialog.bytes!));
    expect(data.transactions, isEmpty);
    expect(find.textContaining('Backup saved'), findsOneWidget);
  });

  testWidgets('cancelling the dialog shows no message',
      (tester) async {
    final dialog = _FakeSaveDialog(result: null);
    await tester.pumpWidget(_buildWidget(saveDialog: dialog));

    await tester.tap(find.text('Save to file'));
    await tester.pumpAndSettle();

    expect(dialog.calls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('shows the Import backup button', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(find.text('Import backup'), findsOneWidget);
  });

  testWidgets('shows the description text', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(
      find.textContaining('Export all your data'),
      findsOneWidget,
    );
  });

  testWidgets('renders without Flutter exceptions', (tester) async {
    await tester.pumpWidget(_buildWidget());
    expect(tester.takeException(), isNull);
  });
}
