import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

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

  /// Mostra un dialog per inserire il nome di una nuova categoria.
  /// Usa [StatefulBuilder] per gestire lo stato dell'errore di validazione
  /// all'interno del dialog senza ricostruire l'intera schermata.
  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    // read: accede al provider senza sottoscriversi (azione one-shot)
    final provider = context.read<CategoryProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nuova Categoria'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nome categoria',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                // Permette di confermare con il tasto invio della tastiera
                onSubmitted: (_) {
                  _tryAdd(controller, provider, dialogContext, (err) {
                    setDialogState(() => errorText = err);
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () {
                    _tryAdd(controller, provider, dialogContext, (err) {
                      setDialogState(() => errorText = err);
                    });
                  },
                  child: const Text('Aggiungi'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => controller.dispose());
  }

  /// Valida il nome e, se valido, aggiunge la categoria e chiude il dialog.
  /// In caso di errore aggiorna il messaggio di errore tramite [setError].
  void _tryAdd(
    TextEditingController controller,
    CategoryProvider provider,
    BuildContext dialogContext,
    void Function(String?) setError,
  ) {
    final name = controller.text.trim();
    if (name.isEmpty) {
      setError('Il nome non può essere vuoto');
      return;
    }
    if (provider.categoryExists(name)) {
      setError('Categoria già esistente');
      return;
    }
    // Chiude il dialog PRIMA di aggiungere la categoria, così il
    // notifyListeners() non avviene durante il build scope del dialog
    Navigator.of(dialogContext).pop();
    provider.addCategory(name);
  }
}
