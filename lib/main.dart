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

/// App entry point.
void main() => runBudgetApp();

/// Initializes Hive (local database), registers the TypeAdapters for the
/// Transaction, TransactionTemplate and Category models, loads the Italian
/// locale data and starts the app.
///
/// [storagePath] overrides the default data directory (see
/// [appStorageDirectory]): integration tests use it to work on a temporary
/// directory without touching the real data.
Future<void> runBudgetApp({String? storagePath}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive in the data directory (the web needs no path)
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Hive.init(storagePath ?? await appStorageDirectory());
  }

  // Register the adapters only once (useful in tests)
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TransactionTemplateAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(CategoryAdapter());
  }

  // Open the boxes (created if missing)
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<TransactionTemplate>('templates');
  await Hive.openBox<Category>('categories');

  // Load the Italian formatting data (dates, month names)
  await initializeDateFormatting('it');

  runApp(const BudgetApp());
}

/// Root widget of the app.
/// Sets up the [MultiProvider] for global state management
/// (TransactionProvider + TemplateProvider + CategoryProvider) and the
/// Material 3 theme with a teal primary color.
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
