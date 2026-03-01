import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../widgets/confirm_delete_dialog.dart';

/// Schermata per visualizzare e gestire le categorie di transazione.
///
/// Mostra la lista di tutte le categorie salvate in ordine alfabetico.
/// Ogni categoria può essere eliminata con swipe verso sinistra.
/// Il FAB apre un dialog per crearne di nuove con validazione
/// (nome non vuoto, nessun duplicato).
///
/// Accessibile dalla HomeScreen tramite l'icona categoria nella AppBar.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch: ricostruisce il widget ad ogni notifyListeners() del provider
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorie'),
        centerTitle: true,
      ),
      // Lista delle categorie, o messaggio se vuota
      body: categories.isEmpty
          ? const Center(
              child: Text(
                'Nessuna categoria',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                // Swipe verso sinistra per eliminare la categoria
                return Dismissible(
                  key: Key(category.id),
                  direction: DismissDirection.endToStart,
                  // Sfondo rosso con icona cestino visibile durante lo swipe
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) =>
                      showConfirmDeleteDialog(context, category.name),
                  onDismissed: (_) => provider.deleteCategory(category.id),
                  child: ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: Text(category.name),
                  ),
                );
              },
            ),
      // Pulsante flottante per aggiungere una nuova categoria
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddCategoryDialog(
        provider: context.read<CategoryProvider>(),
      ),
    );
  }
}

/// Dialog per aggiungere una nuova categoria.
///
/// Usa [StatefulWidget] per gestire il ciclo di vita del [TextEditingController]:
/// [dispose()] viene chiamato da Flutter solo dopo che l'animazione di uscita
/// del dialog è completata e il widget è davvero rimosso dall'albero,
/// evitando l'errore "controller used after disposed".
class _AddCategoryDialog extends StatefulWidget {
  final CategoryProvider provider;

  const _AddCategoryDialog({required this.provider});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tryAdd() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Il nome non può essere vuoto');
      return;
    }
    if (widget.provider.categoryExists(name)) {
      setState(() => _errorText = 'Categoria già esistente');
      return;
    }
    // notifyListeners() avviene mentre il dialog è ancora montato,
    // poi chiudiamo in modo sicuro dopo aver verificato mounted.
    await widget.provider.addCategory(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova Categoria'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Nome categoria',
          border: const OutlineInputBorder(),
          errorText: _errorText,
        ),
        onSubmitted: (_) => _tryAdd(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _tryAdd,
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}
