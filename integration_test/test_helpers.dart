import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_fuck/main.dart' as app;
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';

/// Temporary directory for the integration tests' Hive data.
///
/// The tests clear the boxes at startup: by using this directory (also
/// passed to `runBudgetApp`) they never touch the real app data.
final String testStoragePath =
    Directory.systemTemp.createTempSync('budget_tracker_it_').path;

/// Clears the three boxes in the temporary directory and inserts the given
/// [categories], so the forms that require a category can be used.
Future<void> resetStorage({List<String> categories = const []}) async {
  Hive.init(testStoragePath);
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionTemplateAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CategoryAdapter());
  }
  await (await Hive.openBox<Transaction>('transactions')).clear();
  await (await Hive.openBox<TransactionTemplate>('templates')).clear();
  final categoryBox = await Hive.openBox<Category>('categories');
  await categoryBox.clear();
  for (final (index, name) in categories.indexed) {
    final id = 'c$index';
    await categoryBox.put(id, Category(id: id, name: name));
  }
}

/// Starts the app on the temporary directory and waits for the first full frame.
Future<void> startApp(WidgetTester tester) async {
  await app.runBudgetApp(storagePath: testStoragePath);
  await tester.pumpAndSettle();
}

/// Picks [category] in the searchable category field of the open form.
Future<void> selectCategory(WidgetTester tester, String category) async {
  await tester.tap(find.byType(DropdownMenu<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(
    of: find.byType(MenuItemButton),
    matching: find.text(category),
  ));
  await tester.pumpAndSettle();
}

/// Adds a transaction from the home screen via the new transaction form.
Future<void> addTransaction(
  WidgetTester tester, {
  required String category,
  required String amount,
  required bool isIncome,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();

  await tester.tap(find.text(isIncome ? 'Entrata' : 'Uscita'));
  await tester.pumpAndSettle();

  // The amount is the only TextFormField of the form
  await tester.enterText(find.byType(TextFormField), amount);
  await selectCategory(tester, category);

  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();
}

/// Swipes left on the row containing [text] and waits for the delete
/// confirmation dialog.
///
/// Drags almost the full row width, so the swipe passes the dismiss
/// threshold whatever the window size.
Future<void> swipeToDelete(WidgetTester tester, String text) async {
  final row = find.ancestor(
    of: find.text(text),
    matching: find.byType(Dismissible),
  );
  final width = tester.getSize(row).width;
  await tester.drag(row, Offset(-width * 0.9, 0));
  await tester.pumpAndSettle();
  expect(find.text('Conferma eliminazione'), findsOneWidget);
}

/// Waits until [finder] finds at least one widget, pumping frames.
///
/// Needed after operations that write to Hive: the screen can update
/// just after [WidgetTester.pumpAndSettle], when the disk write has
/// finished (e.g. the totals after a delete).
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}
