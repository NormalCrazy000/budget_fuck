import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'confirm_delete_dialog.dart';

/// Widget per visualizzare una singola transazione nella lista.
///
/// Mostra:
/// - Icona colorata (verde freccia giù per entrate, rosso freccia su per uscite)
/// - Nome della categoria come titolo
/// - Data in formato dd/MM/yyyy come sottotitolo
/// - Importo con segno + o - e colore verde/rosso
///
/// Supporta swipe da destra a sinistra per eliminare (Dismissible).
class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac');
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dismissible(
      key: Key(transaction.id),
      // Solo swipe verso sinistra (end to start)
      direction: DismissDirection.endToStart,
      // Sfondo rosso con icona cestino visibile durante lo swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) =>
          showConfirmDeleteDialog(context, transaction.category),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        // Icona circolare colorata per distinguere entrate da uscite
        leading: CircleAvatar(
          backgroundColor:
              transaction.isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            transaction.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: transaction.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(transaction.category),
        subtitle: Text(dateFormat.format(transaction.date)),
        // Importo formattato con segno e colore
        trailing: Text(
          '${transaction.isIncome ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
          style: TextStyle(
            color: transaction.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
