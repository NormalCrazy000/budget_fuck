import 'dart:io';

import 'package:budget_fuck/main.dart';
import 'package:budget_fuck/models/category.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Runs the whole app (real providers on a temporary Hive directory) with a
/// simulated device language, to check how the app language is chosen.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TransactionAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(CategoryAdapter());
  });

  /// Opens the boxes on a fresh temporary directory, optionally saving
  /// [savedLanguage] as the language chosen in Settings.
  ///
  /// Hive does real file I/O, so it must run in [WidgetTester.runAsync]
  /// (widget tests use a fake clock that real futures never complete on).
  Future<void> openStorage(WidgetTester tester, {String? savedLanguage}) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(dir.path);
      await Hive.openBox<Transaction>('transactions');
      await Hive.openBox<TransactionTemplate>('templates');
      await Hive.openBox<Category>('categories');
      final settings = await Hive.openBox<String>(SettingsProvider.boxName);
      if (savedLanguage != null) {
        await settings.put(SettingsProvider.languageKey, savedLanguage);
      }
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
    });
  }

  /// Starts the app as if the device language list was [deviceLocales].
  Future<void> startWithDeviceLocales(
    WidgetTester tester,
    List<Locale> deviceLocales, {
    String? savedLanguage,
  }) async {
    await openStorage(tester, savedLanguage: savedLanguage);
    tester.platformDispatcher.localesTestValue = deviceLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const BudgetApp());
    await tester.pumpAndSettle();
  }

  testWidgets('device in Italian: the app starts in Italian', (tester) async {
    await startWithDeviceLocales(tester, [const Locale('it', 'IT')]);
    expect(find.text('Entrate'), findsOneWidget);
  });

  testWidgets('device in English: the app starts in English', (tester) async {
    await startWithDeviceLocales(tester, [const Locale('en', 'US')]);
    expect(find.text('Income'), findsOneWidget);
  });

  testWidgets('device in an unsupported language: the app uses English',
      (tester) async {
    await startWithDeviceLocales(tester, [const Locale('de', 'DE')]);
    expect(find.text('Income'), findsOneWidget);
  });

  testWidgets('a language chosen in Settings wins over the device language',
      (tester) async {
    await startWithDeviceLocales(
      tester,
      [const Locale('it', 'IT')],
      savedLanguage: 'en',
    );
    expect(find.text('Income'), findsOneWidget);
  });
}
