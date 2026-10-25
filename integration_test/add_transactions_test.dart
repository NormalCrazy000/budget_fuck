// Le print mostrano l'avanzamento dei passi durante i test di integrazione.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Pulire il database prima di ogni test
    await resetStorage(categories: ['Stipendio', 'Affitto']);
  });

  testWidgets('Aggiungere entrata e uscita e verificare che appaiano nella lista',
      (tester) async {
    await startApp(tester);

    // Verifica stato iniziale: nessuna transazione
    expect(find.text('Nessuna transazione questo mese'), findsOneWidget);

    // --- Aggiungere un'ENTRATA ---
    await addTransaction(
      tester,
      category: 'Stipendio',
      amount: '1500',
      isIncome: true,
    );

    // Torniamo alla home - verificare che l'entrata appaia
    expect(find.text('Stipendio'), findsOneWidget);
    // Il messaggio "Nessuna transazione" non deve più apparire
    expect(find.text('Nessuna transazione questo mese'), findsNothing);

    // --- Aggiungere un'USCITA ---
    await addTransaction(
      tester,
      category: 'Affitto',
      amount: '800',
      isIncome: false,
    );

    // Verificare che entrambe le transazioni appaiano nella lista
    expect(find.text('Stipendio'), findsOneWidget);
    expect(find.text('Affitto'), findsOneWidget);

    // Verificare che i totali siano corretti
    // Entrate: 1500, Uscite: 800, Bilancio: 700
    expect(find.textContaining('1.500'), findsWidgets); // entrate + nella tile
    expect(find.textContaining('800'), findsWidgets); // uscite + nella tile
    expect(find.textContaining('700,00'), findsWidgets); // bilancio

    print('TEST PASSED: Entrata e uscita aggiunte e visibili nella lista');
  });
}
