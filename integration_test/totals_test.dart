// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetStorage(
      categories: ['Stipendio', 'Affitto', 'Freelance', 'Spesa'],
    );
  });

  testWidgets('Verificare che i totali si aggiornino correttamente',
      (tester) async {
    await startApp(tester);

    // --- Stato iniziale: tutti i totali a 0 ---
    // Le card mostrano €0,00 per entrate, uscite, bilancio
    expect(find.textContaining('0,00'), findsWidgets);
    print('OK: Totali iniziali a zero');

    // --- Aggiungere prima entrata: Stipendio 2000 ---
    await addTransaction(
      tester,
      category: 'Stipendio',
      amount: '2000',
      isIncome: true,
    );

    // Entrate: 2.000,00 | Uscite: 0,00 | Bilancio: 2.000,00
    expect(find.textContaining('2.000'), findsWidgets);
    print('OK: Dopo entrata 2000 - totali aggiornati');

    // --- Aggiungere uscita: Affitto 800 ---
    await addTransaction(
      tester,
      category: 'Affitto',
      amount: '800',
      isIncome: false,
    );

    // Entrate: 2.000,00 | Uscite: 800,00 | Bilancio: 1.200,00
    expect(find.textContaining('2.000'), findsWidgets); // entrate
    expect(find.textContaining('800'), findsWidgets); // uscite
    expect(find.textContaining('1.200'), findsWidgets); // bilancio
    print('OK: Dopo uscita 800 - entrate 2000, uscite 800, bilancio 1200');

    // --- Aggiungere seconda entrata: Freelance 500 ---
    await addTransaction(
      tester,
      category: 'Freelance',
      amount: '500',
      isIncome: true,
    );

    // Entrate: 2.500,00 | Uscite: 800,00 | Bilancio: 1.700,00
    expect(find.textContaining('2.500'), findsWidgets); // entrate
    expect(find.textContaining('800'), findsWidgets); // uscite
    expect(find.textContaining('1.700'), findsWidgets); // bilancio
    print('OK: Dopo entrata 500 - entrate 2500, uscite 800, bilancio 1700');

    // --- Aggiungere seconda uscita: Spesa 300 ---
    await addTransaction(
      tester,
      category: 'Spesa',
      amount: '300',
      isIncome: false,
    );

    // Entrate: 2.500,00 | Uscite: 1.100,00 | Bilancio: 1.400,00
    expect(find.textContaining('2.500'), findsWidgets); // entrate
    expect(find.textContaining('1.100'), findsWidgets); // uscite
    expect(find.textContaining('1.400'), findsWidgets); // bilancio
    print('OK: Dopo uscita 300 - entrate 2500, uscite 1100, bilancio 1400');

    // --- Eliminare "Spesa" (swipe + conferma) e verificare ricalcolo ---
    await swipeToDelete(tester, 'Spesa');
    await tester.tap(find.text('Elimina'));
    // I totali si aggiornano quando l'eliminazione su Hive è completata
    await waitFor(tester, find.textContaining('1.700'));

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
