import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../utils/search.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/search_field.dart';

/// Screen to view and manage transaction categories.
///
/// Shows all saved categories in alphabetical order,
/// filterable with the search bar at the top.
/// Each category can be deleted by swiping left.
/// The FAB opens a dialog to create new ones, with validation
/// (non-empty name, no duplicates) and suggestions of similar categories.
///
/// Reached from HomeScreen via the category icon in the AppBar.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    // watch: rebuilds the widget on every notifyListeners() of the provider
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories
        .where((c) => matchesSearch(c.name, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categorie'), centerTitle: true),
      body: Column(
        children: [
          SearchField(
            hintText: 'Cerca categoria',
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(child: _buildList(provider, categories)),
        ],
      ),
      // Floating button to add a new category
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// The filtered categories, or a message when there is nothing to show.
  Widget _buildList(CategoryProvider provider, List<Category> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          provider.categories.isEmpty ? 'Nessuna categoria' : 'Nessun risultato',
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        // Swipe left to delete the category
        return Dismissible(
          key: Key(category.id),
          direction: DismissDirection.endToStart,
          // Red background with a trash icon shown while swiping
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

/// Dialog to add a new category.
///
/// Uses a [StatefulWidget] to manage the [TextEditingController] lifecycle:
/// Flutter calls [dispose()] only after the dialog exit animation has
/// completed and the widget is really removed from the tree,
/// avoiding the "controller used after disposed" error.
class _AddCategoryDialog extends StatefulWidget {
  final CategoryProvider provider;

  const _AddCategoryDialog({required this.provider});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  /// Maximum number of similar categories shown below the field.
  static const _maxSuggestions = 5;

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
    // notifyListeners() happens while the dialog is still mounted,
    // then we close it safely after checking mounted.
    await widget.provider.addCategory(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Existing categories similar to the typed text, to avoid duplicates
    final similar = _controller.text.trim().isEmpty
        ? const <String>[]
        : widget.provider.categories
              .map((c) => c.name)
              .where((name) => matchesSearch(name, _controller.text))
              .take(_maxSuggestions)
              .toList();

    return AlertDialog(
      title: const Text('Nuova Categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nome categoria',
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            // setState to refresh the suggestions on every keystroke
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _tryAdd(),
          ),
          if (similar.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Già esistenti:', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final name in similar)
                  Chip(label: Text(name), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(onPressed: _tryAdd, child: const Text('Aggiungi')),
      ],
    );
  }
}
