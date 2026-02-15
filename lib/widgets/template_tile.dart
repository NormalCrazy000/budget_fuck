import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_template.dart';

/// Widget per visualizzare un singolo template nella lista.
///
/// Simile a [TransactionTile] ma al posto della data mostra
/// il tipo di template ("Entrata" o "Uscita") come sottotitolo.
///
/// Mostra:
/// - Icona colorata (verde freccia giù per entrate, rosso freccia su per uscite)
/// - Nome della categoria come titolo
/// - Tipo: "Entrata" o "Uscita"
/// - Importo con segno + o - e colore verde/rosso
///
/// Supporta swipe da destra a sinistra per eliminare (Dismissible).
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
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac');

    return Dismissible(
      key: Key(template.id),
      // Solo swipe verso sinistra (end to start)
      direction: DismissDirection.endToStart,
      // Sfondo rosso con icona cestino visibile durante lo swipe
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      // Callback chiamato dopo il completamento dello swipe
      onDismissed: (_) => onDelete(),
      child: ListTile(
        // Icona circolare colorata per distinguere entrate da uscite
        leading: CircleAvatar(
          backgroundColor:
              template.isIncome ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            template.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: template.isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(template.category),
        // Al posto della data, mostra il tipo di transazione
        subtitle: Text(template.isIncome ? 'Entrata' : 'Uscita'),
        // Importo formattato con segno e colore
        trailing: Text(
          '${template.isIncome ? '+' : '-'}${currencyFormat.format(template.amount)}',
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
