// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/models/transaction_template.dart';
import 'package:budget_fuck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TransactionTemplateAdapter());
    }
    final box = await Hive.openBox<Transaction>('transactions');
    await box.clear();
    final templateBox = await Hive.openBox<TransactionTemplate>('templates');
    await templateBox.clear();
  });

  Future<void> addTransaction(
    WidgetTester tester, {
    required String title,
    required String amount,
    required bool isIncome,
  }) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    if (isIncome) {
      await tester.tap(find.text('Entrata'));
    } else {
      await tester.tap(find.text('Uscita'));
    }
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, title);
    await tester.enterText(find.byType(TextFormField).last, amount);

    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
  }

  testWidgets('Verificare che i totali si aggiornino correttamente',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // --- Stato iniziale: tutti i totali a 0 ---
    // Le card mostrano €0,00 per entrate, uscite, bilancio
    final zeroMatches = find.textContaining('0,00');
    expect(zeroMatches, findsWidgets);
    print('OK: Totali iniziali a zero');

    // --- Aggiungere prima entrata: Stipendio 2000 ---
    await addTransaction(tester, title: 'Stipendio', amount: '2000', isIncome: true);

    // Entrate: 2.000,00 | Uscite: 0,00 | Bilancio: 2.000,00
    expect(find.textContaining('2.000'), findsWidgets);
    print('OK: Dopo entrata 2000 - totali aggiornati');

    // --- Aggiungere uscita: Affitto 800 ---
    await addTransaction(tester, title: 'Affitto', amount: '800', isIncome: false);

    // Entrate: 2.000,00 | Uscite: 800,00 | Bilancio: 1.200,00
    expect(find.textContaining('2.000'), findsWidgets); // entrate
    expect(find.textContaining('800'), findsWidgets);   // uscite
    expect(find.textContaining('1.200'), findsWidgets); // bilancio
    print('OK: Dopo uscita 800 - entrate 2000, uscite 800, bilancio 1200');

    // --- Aggiungere seconda entrata: Freelance 500 ---
    await addTransaction(tester, title: 'Freelance', amount: '500', isIncome: true);

    // Entrate: 2.500,00 | Uscite: 800,00 | Bilancio: 1.700,00
    expect(find.textContaining('2.500'), findsWidgets); // entrate
    expect(find.textContaining('800'), findsWidgets);   // uscite
    expect(find.textContaining('1.700'), findsWidgets); // bilancio
    print('OK: Dopo entrata 500 - entrate 2500, uscite 800, bilancio 1700');

    // --- Aggiungere seconda uscita: Spesa 300 ---
    await addTransaction(tester, title: 'Spesa', amount: '300', isIncome: false);

    // Entrate: 2.500,00 | Uscite: 1.100,00 | Bilancio: 1.400,00
    expect(find.textContaining('2.500'), findsWidgets); // entrate
    expect(find.textContaining('1.100'), findsWidgets); // uscite
    expect(find.textContaining('1.400'), findsWidgets); // bilancio
    print('OK: Dopo uscita 300 - entrate 2500, uscite 1100, bilancio 1400');

    // --- Eliminare una transazione (swipe su "Spesa") e verificare ricalcolo ---
    final spesaTile = find.ancestor(
      of: find.text('Spesa'),
      matching: find.byType(Dismissible),
    );
    await tester.fling(spesaTile, const Offset(-600, 0), 1500);
    // Lasciare tempo all'animazione di dismissal e al rebuild del provider
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // "Spesa" non deve più essere visibile
    expect(find.text('Spesa'), findsNothing);

    // Entrate: 2.500,00 | Uscite: 800,00 | Bilancio: 1.700,00
    // Verifichiamo le 3 transazioni rimaste
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Freelance'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);
    expect(find.textContaining('2.500'), findsWidgets); // entrate invariate
    expect(find.textContaining('1.700'), findsWidgets); // bilancio ricalcolato
    print('OK: Dopo eliminazione Spesa - uscite tornate a 800, bilancio 1700');

    print('\nTEST PASSED: Tutti i totali si aggiornano correttamente');
  });
}
