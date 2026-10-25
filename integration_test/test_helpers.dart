import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_fuck/main.dart' as app;
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';

/// Cartella temporanea per i dati Hive dei test di integrazione.
///
/// I test cancellano i box all'avvio: usando questa cartella (passata anche
/// a `runBudgetApp`) non toccano mai i dati reali dell'app.
final String testStoragePath =
    Directory.systemTemp.createTempSync('budget_tracker_it_').path;

/// Svuota i tre box nella cartella temporanea e inserisce le [categories]
/// indicate, così i form che richiedono una categoria sono utilizzabili.
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

/// Avvia l'app sulla cartella temporanea e attende il primo frame completo.
Future<void> startApp(WidgetTester tester) async {
  await app.runBudgetApp(storagePath: testStoragePath);
  await tester.pumpAndSettle();
}

/// Sceglie [category] nel campo categoria con ricerca del form aperto.
Future<void> selectCategory(WidgetTester tester, String category) async {
  await tester.tap(find.byType(DropdownMenu<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(
    of: find.byType(MenuItemButton),
    matching: find.text(category),
  ));
  await tester.pumpAndSettle();
}

/// Aggiunge una transazione dalla Home tramite il form "Nuova Transazione".
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

  // L'importo è l'unico TextFormField del form
  await tester.enterText(find.byType(TextFormField), amount);
  await selectCategory(tester, category);

  await tester.tap(find.text('Salva'));
  await tester.pumpAndSettle();
}

/// Fa lo swipe verso sinistra sulla riga che contiene [text] e attende
/// il dialog "Conferma eliminazione".
///
/// Trascina per quasi tutta la larghezza della riga, così lo swipe supera
/// la soglia di eliminazione qualunque sia la dimensione della finestra.
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

/// Attende che [finder] trovi almeno un widget, aggiornando lo schermo.
///
/// Serve dopo le operazioni che scrivono su Hive: lo schermo può aggiornarsi
/// un attimo dopo [WidgetTester.pumpAndSettle], quando la scrittura su disco
/// è terminata (es. i totali dopo un'eliminazione).
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
