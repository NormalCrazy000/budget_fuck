import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import 'confirm_delete_dialog.dart';

/// Shows a single transaction in a list.
///
/// Shows:
/// - colored icon (green down arrow for income, red up arrow for expenses)
/// - category name as title
/// - date in dd/MM/yyyy format as subtitle
/// - amount with + or - sign, green/red
///
/// Swipe right-to-left to delete (Dismissible).
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
      // Swipe to the left only (end to start)
      direction: DismissDirection.endToStart,
      // Red background with a trash icon shown while swiping
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
        // Colored circular icon to tell income from expenses
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
        // Amount formatted with sign and color
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
