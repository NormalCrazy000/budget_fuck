import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';

/// Entry point dell'applicazione.
/// Inizializza Hive (database locale), registra il TypeAdapter per il modello
/// Transaction, carica la localizzazione italiana e avvia l'app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Hive per Flutter (imposta il path di storage)
  await Hive.initFlutter();

  // Registra l'adapter solo se non è già registrato (utile nei test)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }

  // Apre il box delle transazioni (lo crea se non esiste)
  await Hive.openBox<Transaction>('transactions');

  // Inizializza i dati di formattazione per la lingua italiana (date, mesi)
  await initializeDateFormatting('it');

  runApp(const BudgetApp());
}

/// Widget radice dell'applicazione.
/// Configura il [ChangeNotifierProvider] per lo state management globale
/// e definisce il tema Material 3 con colore primario teal.
class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Il provider viene creato una sola volta e condiviso con tutta l'app
      create: (_) => TransactionProvider(),
      child: MaterialApp(
        title: 'Budget Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
