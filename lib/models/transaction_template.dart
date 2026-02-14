import 'package:hive/hive.dart';

part 'transaction_template.g.dart';

/// Modello che rappresenta un template di transazione predefinito.
///
/// Simile a [Transaction] ma senza il campo [date]: il template definisce
/// una transazione ricorrente (es. stipendio, affitto, bollette) che può
/// essere applicata a qualsiasi mese dall'utente.
///
/// Estende [HiveObject] per la persistenza locale.
/// Il [TypeAdapter] viene generato automaticamente da `hive_generator`
/// tramite il file `transaction_template.g.dart`.
///
/// Campi:
/// - [id]: identificativo univoco (timestamp in millisecondi)
/// - [title]: descrizione del template (es. "Stipendio", "Affitto")
/// - [amount]: importo in euro (sempre positivo, il segno è dato da [isIncome])
/// - [isIncome]: true = entrata, false = uscita
/// - [category]: categoria opzionale per raggruppamenti futuri
@HiveType(typeId: 1)
class TransactionTemplate extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isIncome;

  @HiveField(4)
  final String? category;

  TransactionTemplate({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    this.category,
  });
}
