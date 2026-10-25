import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/search.dart';
import '../widgets/search_field.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'apply_templates_screen.dart';
import 'backup_screen.dart';
import 'categories_screen.dart';
import 'stats_screen.dart';
import 'templates_screen.dart';

/// Main screen of the app.
///
/// Layout from top to bottom:
/// 1. month/year selector with navigation arrows
/// 2. three summary cards (income, expenses, balance)
/// 3. search bar by category (totals still cover the whole month)
/// 4. scrollable list of the selected month's transactions
/// 5. FAB to add a new transaction
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // watch: rebuilds the widget on every notifyListeners() of the provider
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions
        .where((t) => matchesSearch(t.category, _query))
        .toList();
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac');
    final monthFormat = DateFormat('MMMM yyyy', 'it');
    final monthDate = DateTime(provider.selectedYear, provider.selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiche',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StatsScreen(),
                ),
              );
            },
          ),
          // Go to category management
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Gestisci Categorie',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CategoriesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Gestisci Template',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TemplatesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            tooltip: 'Applica Template',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ApplyTemplatesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'Backup & Ripristino',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BackupScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Month selector: left arrow, month name, right arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: provider.previousMonth,
                ),
                Text(
                  monthFormat.format(monthDate).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: provider.nextMonth,
                ),
              ],
            ),
          ),

          // Three side-by-side cards with the month totals
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _SummaryCard(
                  label: 'Entrate',
                  amount: currencyFormat.format(provider.totalIncome),
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Uscite',
                  amount: currencyFormat.format(provider.totalExpense),
                  color: Colors.red,
                ),
                const SizedBox(width: 8),
                _SummaryCard(
                  label: 'Bilancio',
                  amount: currencyFormat.format(provider.balance),
                  // Blue if positive, orange if negative
                  color: provider.balance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),

          const Divider(),

          SearchField(
            hintText: 'Cerca per categoria',
            onChanged: (value) => setState(() => _query = value),
          ),

          // Filtered transactions, or a message when empty
          Expanded(
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      provider.transactions.isEmpty
                          ? 'Nessuna transazione questo mese'
                          : 'Nessun risultato',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return TransactionTile(
                        transaction: transaction,
                        onDelete: () =>
                            provider.deleteTransaction(transaction.id),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating button to add a new transaction
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Compact card showing a single total (income, expenses or balance).
/// Expands to take 1/3 of the available width.
class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // FittedBox scales the text down if the amount is too long
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
