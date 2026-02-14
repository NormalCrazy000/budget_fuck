import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/transaction_template.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';

/// Schermata per applicare template predefiniti a un mese specifico.
///
/// Permette all'utente di:
/// - Selezionare il mese/anno di destinazione con navigazione avanti/indietro
/// - Scegliere quali template applicare tramite checkbox
/// - Usare "Seleziona Tutti"/"Deseleziona Tutti" per selezione rapida
/// - Applicare i template selezionati, creando le transazioni corrispondenti
///
/// Ogni template selezionato genera una [Transaction] con data al giorno 15
/// del mese scelto. Gli ID sono univoci grazie al formato `'${timestamp}_$index'`.
///
/// Accessibile dalla HomeScreen tramite l'icona play nella AppBar.
class ApplyTemplatesScreen extends StatefulWidget {
  const ApplyTemplatesScreen({super.key});

  @override
  State<ApplyTemplatesScreen> createState() => _ApplyTemplatesScreenState();
}

class _ApplyTemplatesScreenState extends State<ApplyTemplatesScreen> {
  /// Set degli ID dei template attualmente selezionati
  final Set<String> _selectedIds = {};

  /// Mese e anno di destinazione per le transazioni generate
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default: mese corrente
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  /// Aggiunge tutti i template alla selezione.
  void _selectAll(List<TransactionTemplate> templates) {
    setState(() {
      _selectedIds.addAll(templates.map((t) => t.id));
    });
  }

  /// Rimuove tutti i template dalla selezione.
  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  /// Crea una [Transaction] per ogni template selezionato e la salva.
  ///
  /// Le transazioni vengono create con data al giorno 15 del mese scelto.
  /// L'ID di ogni transazione usa il formato `'${timestamp}_$index'` per
  /// garantire univocità anche quando si applicano più template nello stesso istante.
  /// Dopo l'applicazione, naviga la HomeScreen al mese di destinazione.
  Future<void> _apply() async {
    final templateProvider = context.read<TemplateProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final templates = templateProvider.templates
        .where((t) => _selectedIds.contains(t.id))
        .toList();

    if (templates.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Data fissa al 15 del mese: giorno neutro per il filtro mensile
    final date = DateTime(_selectedYear, _selectedMonth, 15);

    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      final transaction = Transaction(
        id: '${timestamp}_$i',
        title: t.title,
        amount: t.amount,
        isIncome: t.isIncome,
        date: date,
        category: t.category,
      );
      await transactionProvider.addTransaction(transaction);
    }

    // Dopo l'applicazione, aggiorna il mese visualizzato nella home
    if (mounted) {
      transactionProvider.setMonth(_selectedMonth, _selectedYear);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateProvider>().templates;
    final monthFormat = DateFormat('MMMM yyyy', 'it');
    final monthDate = DateTime(_selectedYear, _selectedMonth);
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '\u20ac');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applica Template'),
        centerTitle: true,
      ),
      body: templates.isEmpty
          ? const Center(
              child: Text(
                'Nessun template disponibile',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : Column(
              children: [
                // Selettore mese: freccia sinistra, nome mese, freccia destra
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 1) {
                              _selectedMonth = 12;
                              _selectedYear--;
                            } else {
                              _selectedMonth--;
                            }
                          });
                        },
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
                        onPressed: () {
                          setState(() {
                            if (_selectedMonth == 12) {
                              _selectedMonth = 1;
                              _selectedYear++;
                            } else {
                              _selectedMonth++;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Pulsanti per selezione/deselezione rapida di tutti i template
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => _selectAll(templates),
                        child: const Text('Seleziona Tutti'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _deselectAll,
                        child: const Text('Deseleziona Tutti'),
                      ),
                    ],
                  ),
                ),
                // Lista template con checkbox per selezione individuale
                Expanded(
                  child: ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final template = templates[index];
                      final isSelected = _selectedIds.contains(template.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(template.id);
                            } else {
                              _selectedIds.remove(template.id);
                            }
                          });
                        },
                        secondary: CircleAvatar(
                          backgroundColor: template.isIncome
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            template.isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: template.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(template.title),
                        subtitle: Text(
                          '${template.isIncome ? '+' : '-'}${currencyFormat.format(template.amount)}',
                          style: TextStyle(
                            color: template.isIncome ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Pulsante applica: disabilitato se nessun template è selezionato
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedIds.isEmpty ? null : _apply,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Applica (${_selectedIds.length})',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
