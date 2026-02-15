import 'package:hive/hive.dart';

part 'category.g.dart';

/// Modello che rappresenta una categoria di transazione.
///
/// Le categorie sono condivise tra entrate e uscite e vengono
/// selezionate dall'utente al momento della creazione di una transazione
/// o di un template.
///
/// Estende [HiveObject] per il supporto alla persistenza locale.
/// Il [TypeAdapter] viene generato automaticamente da `hive_generator`
/// tramite il file `category.g.dart`.
///
/// Campi:
/// - [id]: identificativo univoco (timestamp in millisecondi)
/// - [name]: nome della categoria (es. "Alimentari", "Trasporti")
@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Category({
    required this.id,
    required this.name,
  });
}
