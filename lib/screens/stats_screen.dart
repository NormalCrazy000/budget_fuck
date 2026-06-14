import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final monthFormat = DateFormat('MMMM yyyy', 'it');
    final monthDate = DateTime(provider.selectedYear, provider.selectedMonth);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistiche'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Uscite'),
              Tab(text: 'Entrate'),
            ],
          ),
        ),
        body: Column(
          children: [
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
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _CategoryBreakdown(
                    transactions: provider.transactions.where((t) => !t.isIncome).toList(),
                    isExpense: true,
                  ),
                  _CategoryBreakdown(
                    transactions: provider.transactions.where((t) => t.isIncome).toList(),
                    isExpense: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isExpense;

  const _CategoryBreakdown({
    required this.transactions,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          isExpense ? 'Nessuna uscita questo mese' : 'Nessuna entrata questo mese',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    final double total = transactions.fold(0.0, (sum, t) => sum + t.amount);

    final Map<String, List<Transaction>> byCategory = {};
    for (final t in transactions) {
      byCategory.putIfAbsent(t.category, () => []).add(t);
    }

    final entries = byCategory.entries.toList()
      ..sort((a, b) {
        final sumA = a.value.fold(0.0, (s, t) => s + t.amount);
        final sumB = b.value.fold(0.0, (s, t) => s + t.amount);
        return sumB.compareTo(sumA);
      });

    final color = isExpense ? Colors.red : Colors.green;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Totale uscite' : 'Totale entrate',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                currencyFormat.format(total),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final categoryTotal = entry.value.fold(0.0, (s, t) => s + t.amount);
              final count = entry.value.length;
              final percent = total > 0 ? categoryTotal / total : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyFormat.format(categoryTotal),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: color.withAlpha(40),
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$count ${count == 1 ? 'transazione' : 'transazioni'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          '${(percent * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
