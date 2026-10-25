import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_template.dart';
import '../providers/template_provider.dart';
import '../utils/search.dart';
import '../widgets/search_field.dart';
import '../widgets/template_tile.dart';
import 'add_template_screen.dart';

/// Schermata per visualizzare e gestire i template predefiniti.
///
/// Mostra la lista di tutti i template salvati, filtrabile per categoria
/// con la barra di ricerca in alto. Ogni template può essere
/// eliminato con swipe verso sinistra. Il FAB apre [AddTemplateScreen]
/// per crearne di nuovi.
///
/// Accessibile dalla HomeScreen tramite l'icona lista nella AppBar.
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // watch: ricostruisce il widget ad ogni notifyListeners() del provider
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
      // Pulsante flottante per aggiungere un nuovo template
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

  /// Lista dei template filtrati, o messaggio se non c'è nulla da mostrare.
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
