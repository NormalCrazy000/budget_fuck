import 'package:hive/hive.dart';

part 'transaction.g.dart';

/// Modello che rappresenta una singola transazione finanziaria.
///
/// Estende [HiveObject] per il supporto alla persistenza locale.
/// Il [TypeAdapter] viene generato automaticamente da `hive_generator`
/// tramite il file `transaction.g.dart`.
///
/// Campi:
/// - [id]: identificativo univoco (timestamp in millisecondi)
/// - [amount]: importo in euro (sempre positivo, il segno è dato da [isIncome])
/// - [isIncome]: true = entrata, false = uscita
/// - [date]: data della transazione, usata per il filtro mensile
/// - [category]: categoria della transazione (obbligatoria, scelta da [CategoryProvider])
///
/// Nota: il campo [HiveField(1)] (ex title) non è più utilizzato ma viene
/// mantenuto nell'adapter per retrocompatibilità con dati esistenti su Hive.
@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final bool isIncome;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String category;

  Transaction({
    required this.id,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.category,
  });
}
