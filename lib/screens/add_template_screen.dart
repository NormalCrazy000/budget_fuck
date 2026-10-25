import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../providers/category_provider.dart';
import '../providers/template_provider.dart';
import '../widgets/category_picker_field.dart';

/// Screen to create a new predefined transaction template.
///
/// Like [AddTransactionScreen] but without the date picker,
/// since templates do not depend on the month.
///
/// Contains a form with:
/// - income/expense toggle (green/red)
/// - searchable category field (required, filled from [CategoryProvider])
/// - numeric amount field with validation
/// - save button that persists to Hive and goes back to the template list
class AddTemplateScreen extends StatefulWidget {
  const AddTemplateScreen({super.key});

  @override
  State<AddTemplateScreen> createState() => _AddTemplateScreenState();
}

class _AddTemplateScreenState extends State<AddTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isIncome = true; // Default: income
  String? _selectedCategory; // Category picked in the form

  // Categories loaded once when the screen opens.
  // No context.watch needed: the list does not change while the form is open.
  List<String> _categoryNames = [];
  bool _categoriesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_categoriesLoaded) {
      // read: one-shot read, does not subscribe to future notifications
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

  /// Validates the form, creates the template and saves it via the provider.
  /// The id is the current timestamp in milliseconds.
  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final template = TransactionTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: double.parse(_amountController.text),
      isIncome: _isIncome,
      category: _selectedCategory!,
    );

    // read: accesses the provider without subscribing (one-shot action)
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
              // Income/expense toggle: two side-by-side buttons with rounded corners
              Row(
                children: [
                  // "Income" button (left half)
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
                  // "Expense" button (right half)
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

              // Amount field (numbers with decimals only)
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

              // Category selection (required) with search.
              // Uses _categoryNames, loaded once in didChangeDependencies.
              CategoryPickerField(
                categoryNames: _categoryNames,
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 24),

              // Save button: color depends on the template type
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
