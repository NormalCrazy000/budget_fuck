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

    // Inserire transazioni in mesi diversi direttamente nel DB
    final now = DateTime.now();

    // Mese corrente: 2 transazioni
    await box.put(
      'current_1',
      Transaction(
        id: 'current_1',
        title: 'Stipendio Febbraio',
        amount: 2000,
        isIncome: true,
        date: DateTime(now.year, now.month, 10),
      ),
    );
    await box.put(
      'current_2',
      Transaction(
        id: 'current_2',
        title: 'Affitto Febbraio',
        amount: 800,
        isIncome: false,
        date: DateTime(now.year, now.month, 5),
      ),
    );

    // Mese precedente: 1 transazione
    final prevMonth = now.month == 1 ? 12 : now.month - 1;
    final prevYear = now.month == 1 ? now.year - 1 : now.year;
    await box.put(
      'prev_1',
      Transaction(
        id: 'prev_1',
        title: 'Stipendio Gennaio',
        amount: 1800,
        isIncome: true,
        date: DateTime(prevYear, prevMonth, 15),
      ),
    );

    // Mese successivo: 1 transazione
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    await box.put(
      'next_1',
      Transaction(
        id: 'next_1',
        title: 'Previsione Marzo',
        amount: 500,
        isIncome: false,
        date: DateTime(nextYear, nextMonth, 20),
      ),
    );
  });

  testWidgets('Cambiare mese e verificare filtro transazioni', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // === MESE CORRENTE (Febbraio 2026) ===
    // Deve mostrare solo le transazioni di febbraio
    expect(find.text('Stipendio Febbraio'), findsOneWidget);
    expect(find.text('Affitto Febbraio'), findsOneWidget);
    // Non deve mostrare transazioni di altri mesi
    expect(find.text('Stipendio Gennaio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    // Totali: entrate 2000, uscite 800, bilancio 1200
    expect(find.textContaining('2.000'), findsWidgets);
    expect(find.textContaining('800'), findsWidgets);
    expect(find.textContaining('1.200'), findsWidgets);
    print('OK: Mese corrente - 2 transazioni, totali corretti');

    // === NAVIGARE AL MESE PRECEDENTE (Gennaio) ===
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    // Deve mostrare solo la transazione di gennaio
    expect(find.text('Stipendio Gennaio'), findsOneWidget);
    // Non deve mostrare transazioni di febbraio o marzo
    expect(find.text('Stipendio Febbraio'), findsNothing);
    expect(find.text('Affitto Febbraio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    // Totali: entrate 1800, uscite 0, bilancio 1800
    expect(find.textContaining('1.800'), findsWidgets);
    print('OK: Mese precedente - solo Stipendio Gennaio, totali ricalcolati');

    // === NAVIGARE AVANTI DI 2 MESI (torna a corrente, poi al successivo) ===
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // Deve mostrare solo la transazione di marzo
    expect(find.text('Previsione Marzo'), findsOneWidget);
    // Non deve mostrare transazioni di altri mesi
    expect(find.text('Stipendio Febbraio'), findsNothing);
    expect(find.text('Affitto Febbraio'), findsNothing);
    expect(find.text('Stipendio Gennaio'), findsNothing);
    // Totali: entrate 0, uscite 500, bilancio -500
    expect(find.textContaining('500'), findsWidgets);
    print('OK: Mese successivo - solo Previsione Marzo, totali ricalcolati');

    // === TORNARE AL MESE CORRENTE E VERIFICARE ===
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    expect(find.text('Stipendio Febbraio'), findsOneWidget);
    expect(find.text('Affitto Febbraio'), findsOneWidget);
    expect(find.text('Stipendio Gennaio'), findsNothing);
    expect(find.text('Previsione Marzo'), findsNothing);
    print('OK: Tornati al mese corrente - transazioni di febbraio ripristinate');

    print('\nTEST PASSED: Il filtro per mese funziona correttamente');
  });
}
