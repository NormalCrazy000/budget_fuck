import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    // watch: rebuilds the widget on every notifyListeners() of the provider
    final provider = context.watch<CategoryProvider>();
    final categories = provider.categories
        .where((c) => matchesSearch(c.name, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories), centerTitle: true),
      body: Column(
        children: [
          SearchField(
            hintText: l10n.searchCategory,
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
          provider.categories.isEmpty
              ? AppLocalizations.of(context).noCategories
              : AppLocalizations.of(context).noResults,
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
      setState(
        () => _errorText = AppLocalizations.of(context).categoryNameEmpty,
      );
      return;
    }
    if (widget.provider.categoryExists(name)) {
      setState(
        () => _errorText = AppLocalizations.of(context).categoryAlreadyExists,
      );
      return;
    }
    // notifyListeners() happens while the dialog is still mounted,
    // then we close it safely after checking mounted.
    await widget.provider.addCategory(name);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Existing categories similar to the typed text, to avoid duplicates
    final similar = _controller.text.trim().isEmpty
        ? const <String>[]
        : widget.provider.categories
              .map((c) => c.name)
              .where((name) => matchesSearch(name, _controller.text))
              .take(_maxSuggestions)
              .toList();

    return AlertDialog(
      title: Text(l10n.newCategory),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.categoryName,
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
            // setState to refresh the suggestions on every keystroke
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _tryAdd(),
          ),
          if (similar.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.similarExistingCategories,
              style: const TextStyle(color: Colors.grey),
            ),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _tryAdd, child: Text(l10n.add)),
      ],
    );
  }
}
