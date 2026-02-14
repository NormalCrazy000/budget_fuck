import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/transaction.dart';
import 'models/transaction_template.dart';
import 'providers/template_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';

/// Entry point dell'applicazione.
/// Inizializza Hive (database locale), registra i TypeAdapter per i modelli
/// Transaction e TransactionTemplate, carica la localizzazione italiana e avvia l'app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Hive per Flutter (imposta il path di storage)
  await Hive.initFlutter();

  // Registra gli adapter solo se non sono già registrati (utile nei test)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionTemplateAdapter());
  }

  // Apre i box (li crea se non esistono)
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<TransactionTemplate>('templates');

  // Inizializza i dati di formattazione per la lingua italiana (date, mesi)
  await initializeDateFormatting('it');

  runApp(const BudgetApp());
}

/// Widget radice dell'applicazione.
/// Configura il [MultiProvider] per lo state management globale
/// (TransactionProvider + TemplateProvider) e definisce il tema
/// Material 3 con colore primario teal.
class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
      ],
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
