import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/transaction_template.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';

/// Screen to apply predefined templates to a specific month.
///
/// Lets the user:
/// - pick the target month/year with previous/next navigation
/// - choose which templates to apply with checkboxes
/// - use "select all"/"deselect all" for quick selection
/// - apply the selected templates, creating the matching transactions
///
/// Each selected template creates a [Transaction] dated the 15th of the
/// chosen month. IDs are unique thanks to the `'${timestamp}_$index'` format.
///
/// Reached from HomeScreen via the play icon in the AppBar.
class ApplyTemplatesScreen extends StatefulWidget {
  const ApplyTemplatesScreen({super.key});

  @override
  State<ApplyTemplatesScreen> createState() => _ApplyTemplatesScreenState();
}

class _ApplyTemplatesScreenState extends State<ApplyTemplatesScreen> {
  /// IDs of the currently selected templates
  final Set<String> _selectedIds = {};

  /// Target month and year for the generated transactions
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    // Default: current month
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  /// Adds every template to the selection.
  void _selectAll(List<TransactionTemplate> templates) {
    setState(() {
      _selectedIds.addAll(templates.map((t) => t.id));
    });
  }

  /// Removes every template from the selection.
  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  /// Creates and saves a [Transaction] for each selected template.
  ///
  /// Transactions are dated the 15th of the chosen month.
  /// Each transaction ID uses the `'${timestamp}_$index'` format to stay
  /// unique even when several templates are applied at the same instant.
  /// Afterwards, HomeScreen is moved to the target month.
  Future<void> _apply() async {
    final templateProvider = context.read<TemplateProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final templates = templateProvider.templates
        .where((t) => _selectedIds.contains(t.id))
        .toList();

    if (templates.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Fixed on the 15th: a neutral day for the monthly filter
    final date = DateTime(_selectedYear, _selectedMonth, 15);

    for (var i = 0; i < templates.length; i++) {
      final t = templates[i];
      final transaction = Transaction(
        id: '${timestamp}_$i',
        amount: t.amount,
        isIncome: t.isIncome,
        date: date,
        category: t.category,
      );
      await transactionProvider.addTransaction(transaction);
    }

    // After applying, update the month shown on the home screen
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
                // Month selector: left arrow, month name, right arrow
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
                // Buttons to quickly select/deselect all templates
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
                // Template list with a checkbox per item
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
                        title: Text(template.category),
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
                // Apply button: disabled when no template is selected
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
