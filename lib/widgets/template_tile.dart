import 'package:flutter/material.dart';
import '../models/transaction_template.dart';
import 'confirm_delete_dialog.dart';
import '../l10n/app_localizations.dart';
import '../utils/formatters.dart';

/// Shows a single template in a list.
///
/// Like [TransactionTile], but shows the template type (income or expense)
/// as subtitle instead of the date.
///
/// Shows:
/// - colored icon (green down arrow for income, red up arrow for expenses)
/// - category name as title
/// - type: income or expense
/// - amount with + or - sign, green/red
///
/// Swipe right-to-left to delete (Dismissible).
class TemplateTile extends StatelessWidget {
  final TransactionTemplate template;
  final VoidCallback onDelete;

  const TemplateTile({
    super.key,
    required this.template,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = currencyFormat(context);

    return Dismissible(
      key: Key(template.id),
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
          showConfirmDeleteDialog(context, template.category),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        // Colored circular icon to tell income from expenses
        leading: CircleAvatar(
          backgroundColor:
              template.isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            template.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: template.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(template.category),
        // Show the transaction type instead of the date
        subtitle: Text(template.isIncome ? l10n.income : l10n.expense),
        // Amount formatted with sign and color
        trailing: Text(
          '${template.isIncome ? '+' : '-'}${currency.format(template.amount)}',
          style: TextStyle(
            color: template.isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
