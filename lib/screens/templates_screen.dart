import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/template_provider.dart';
import '../widgets/template_tile.dart';
import 'add_template_screen.dart';

/// Schermata per visualizzare e gestire i template predefiniti.
///
/// Mostra la lista di tutti i template salvati. Ogni template può essere
/// eliminato con swipe verso sinistra. Il FAB apre [AddTemplateScreen]
/// per crearne di nuovi.
///
/// Accessibile dalla HomeScreen tramite l'icona lista nella AppBar.
class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: ricostruisce il widget ad ogni notifyListeners() del provider
    final provider = context.watch<TemplateProvider>();
    final templates = provider.templates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template'),
        centerTitle: true,
      ),
      // Lista dei template, o messaggio se vuota
      body: templates.isEmpty
          ? const Center(
              child: Text(
                'Nessun template',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return TemplateTile(
                  template: template,
                  onDelete: () => provider.deleteTemplate(template.id),
                );
              },
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
}
