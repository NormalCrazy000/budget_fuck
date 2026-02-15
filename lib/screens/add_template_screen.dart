import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../providers/category_provider.dart';
import '../providers/template_provider.dart';

/// Schermata per creare un nuovo template di transazione predefinito.
///
/// Simile a [AddTransactionScreen] ma senza il selettore data,
/// dato che i template sono indipendenti dal mese.
///
/// Contiene un form con:
/// - Toggle entrata/uscita (verde/rosso)
/// - Dropdown categoria (obbligatorio, popolato da [CategoryProvider])
/// - Campo importo numerico con validazione
/// - Pulsante salva che persiste su Hive e torna alla lista template
class AddTemplateScreen extends StatefulWidget {
  const AddTemplateScreen({super.key});

  @override
  State<AddTemplateScreen> createState() => _AddTemplateScreenState();
}

class _AddTemplateScreenState extends State<AddTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isIncome = true; // Default: entrata
  String? _selectedCategory; // Categoria selezionata dal dropdown

  // Categorie caricate una sola volta all'apertura della schermata.
  // Non serve context.watch perché la lista non cambia mentre il form è aperto.
  List<String> _categoryNames = [];
  bool _categoriesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoriesLoaded) {
      // read: lettura one-shot, non sottoscrive a notifiche future
      _categoryNames = context
          .read<CategoryProvider>()
          .categories
          .map((c) => c.name)
          .toList();
      _categoriesLoaded = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Valida il form, crea il template e lo salva tramite il provider.
  /// L'id viene generato dal timestamp corrente in millisecondi.
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final template = TransactionTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      category: _selectedCategory!,
    );

    // read: accede al provider senza sottoscriversi (azione one-shot)
    context.read<TemplateProvider>().addTemplate(template);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Template'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Toggle Entrata/Uscita: due bottoni affiancati con bordi arrotondati
              Row(
                children: [
                  // Bottone "Entrata" (metà sinistra)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isIncome ? Colors.green : Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Entrata',
                          style: TextStyle(
                            color: _isIncome ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottone "Uscita" (metà destra)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isIncome = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isIncome ? Colors.red : Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Uscita',
                          style: TextStyle(
                            color: !_isIncome ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo importo (solo numeri con decimali)
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Importo (\u20ac)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci un importo';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Inserisci un importo valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dropdown per la selezione della categoria (obbligatoria).
              // Usa _categoryNames caricato una volta in didChangeDependencies.
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                items: _categoryNames
                    .map((name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Seleziona una categoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Pulsante salva: colore dinamico in base al tipo di template
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isIncome ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Salva',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
