import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:budget_fuck/models/transaction.dart';
import 'package:budget_fuck/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Pulire il database prima di ogni test
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    final box = await Hive.openBox<Transaction>('transactions');
    await box.clear();
  });

  testWidgets('Aggiungere entrata e uscita e verificare che appaiano nella lista',
      (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Verifica stato iniziale: nessuna transazione
    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);

    // --- Aggiungere un'ENTRATA ---
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Siamo nella schermata "Nuova Transazione"
    expect(find.text('Nuova Transazione'), findsOneWidget);

    // "Entrata" è selezionato di default, lo confermiamo tappando
    await tester.tap(find.text('Entrata'));
    await tester.pumpAndSettle();

    // Inserire descrizione
    await tester.enterText(find.byType(TextFormField).first, 'Stipendio');
    // Inserire importo
    await tester.enterText(find.byType(TextFormField).last, '1500');

    // Tappare Salva
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Torniamo alla home - verificare che l'entrata appaia
    expect(find.text('Stipendio'), findsOneWidget);
    // Il messaggio "Nessuna transazione" non deve più apparire
    expect(find.text('Nessuna transazione questo mese'), findsNothing);

    // --- Aggiungere un'USCITA ---
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Selezionare "Uscita"
    await tester.tap(find.text('Uscita'));
    await tester.pumpAndSettle();

    // Inserire descrizione
    await tester.enterText(find.byType(TextFormField).first, 'Affitto');
    // Inserire importo
    await tester.enterText(find.byType(TextFormField).last, '800');

    // Tappare Salva
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();

    // Verificare che entrambe le transazioni appaiano nella lista
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);

    // Verificare che i totali siano corretti
    // Entrate: 1500, Uscite: 800, Bilancio: 700
    expect(find.textContaining('1.500'), findsWidgets); // entrate + nella tile
    expect(find.textContaining('800'), findsWidgets);   // uscite + nella tile

    print('TEST PASSED: Entrata e uscita aggiunte e visibili nella lista');
  });
}
