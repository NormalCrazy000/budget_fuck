import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'models/category.dart';
import 'models/transaction.dart';
import 'models/transaction_template.dart';
import 'providers/category_provider.dart';
import 'providers/template_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/home_screen.dart';
import 'services/storage_location.dart';

/// Entry point dell'applicazione.
void main() => runBudgetApp();

/// Inizializza Hive (database locale), registra i TypeAdapter per i modelli
/// Transaction, TransactionTemplate e Category, carica la localizzazione
/// italiana e avvia l'app.
///
/// [storagePath] permette di usare una cartella diversa da quella predefinita
/// (vedi [appStorageDirectory]): i test di integrazione la usano per lavorare
/// su una cartella temporanea senza toccare i dati reali.
Future<void> runBudgetApp({String? storagePath}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Hive nella cartella dei dati (sul web non serve un path)
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Hive.init(storagePath ?? await appStorageDirectory());
  }

  // Registra gli adapter solo se non sono già registrati (utile nei test)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionTemplateAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CategoryAdapter());
  }

  // Apre i box (li crea se non esistono)
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<TransactionTemplate>('templates');
  await Hive.openBox<Category>('categories');

  // Inizializza i dati di formattazione per la lingua italiana (date, mesi)
  await initializeDateFormatting('it');

  runApp(const BudgetApp());
}

/// Widget radice dell'applicazione.
/// Configura il [MultiProvider] per lo state management globale
/// (TransactionProvider + TemplateProvider + CategoryProvider) e definisce
/// il tema Material 3 con colore primario teal.
class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => TemplateProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
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
