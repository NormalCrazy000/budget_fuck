import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'apply_templates_screen.dart';
import 'categories_screen.dart';
import 'stats_screen.dart';
import 'templates_screen.dart';

/// Schermata principale dell'app.
///
/// Layout dall'alto verso il basso:
/// 1. Selettore mese/anno con frecce di navigazione
/// 2. Tre card di riepilogo (Entrate, Uscite, Bilancio)
/// 3. Lista scrollabile delle transazioni del mese selezionato
/// 4. FAB per aggiungere una nuova transazione
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: ricostruisce il widget ad ogni notifyListeners() del provider
    final provider = context.watch<TransactionProvider>();
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
          // Navigazione alla gestione categorie
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
        ],
      ),
      body: Column(
        children: [
          // Selettore mese: freccia sinistra, nome mese, freccia destra
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

          // Tre card affiancate con i totali del mese
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
                  // Blu se positivo, arancione se negativo
                  color: provider.balance >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),

          const Divider(),

          // Lista delle transazioni del mese, o messaggio se vuota
          Expanded(
            child: provider.transactions.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna transazione questo mese',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: provider.transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = provider.transactions[index];
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

      // Pulsante flottante per aggiungere una nuova transazione
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

/// Card compatta per mostrare un singolo totale (entrate, uscite o bilancio).
/// Si espande per occupare 1/3 della larghezza disponibile.
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
              // FittedBox ridimensiona il testo se l'importo è troppo lungo
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
