import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../providers/template_provider.dart';
import '../utils/search.dart';
import '../widgets/search_field.dart';
import '../widgets/template_tile.dart';
import 'add_template_screen.dart';

/// Screen to view and manage the predefined templates.
///
/// Shows all saved templates, filterable by category
/// with the search bar at the top. Each template can be
/// deleted by swiping left. The FAB opens [AddTemplateScreen]
/// to create new ones.
///
/// Reached from HomeScreen via the list icon in the AppBar.
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // watch: rebuilds the widget on every notifyListeners() of the provider
    final provider = context.watch<TemplateProvider>();
    final templates = provider.templates
        .where((t) => matchesSearch(t.category, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SearchField(
            hintText: 'Cerca per categoria',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(child: _buildList(provider, templates)),
        ],
      ),
      // Floating button to add a new template
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddTemplateScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The filtered templates, or a message when there is nothing to show.
  Widget _buildList(
    TemplateProvider provider,
    List<TransactionTemplate> templates,
  ) {
    if (templates.isEmpty) {
      return Center(
        child: Text(
          provider.templates.isEmpty ? 'Nessun template' : 'Nessun risultato',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateTile(
          template: template,
          onDelete: () => provider.deleteTemplate(template.id),
        );
      },
    );
  }
}
