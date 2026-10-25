import 'package:flutter/material.dart';
import '../utils/search.dart';

/// Campo per scegliere una categoria con ricerca, da usare dentro un [Form].
///
/// Sostituisce il menu a tendina classico: l'utente può scrivere nel campo
/// e la lista mostra solo le categorie che contengono il testo digitato
/// (ignorando maiuscole e accenti, vedi [matchesSearch]).
///
/// La validazione fallisce con "Seleziona una categoria" se non è stata
/// scelta una voce dalla lista: il testo digitato da solo non basta.
class CategoryPickerField extends StatefulWidget {
  final List<String> categoryNames;
  final ValueChanged<String?> onChanged;

  const CategoryPickerField({
    super.key,
    required this.categoryNames,
    required this.onChanged,
  });

  @override
  State<CategoryPickerField> createState() => _CategoryPickerFieldState();
}

class _CategoryPickerFieldState extends State<CategoryPickerField> {
  final _controller = TextEditingController();
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Se l'utente modifica il testo dopo aver scelto una categoria,
  /// la scelta viene annullata: il valore deve sempre venire dalla lista.
  void _onTextChanged() {
    final field = _fieldKey.currentState;
    if (field == null || field.value == null) return;
    if (_controller.text != field.value) {
      field.didChange(null);
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Seleziona una categoria';
        }
        return null;
      },
      builder: (field) {
        return DropdownMenu<String>(
          controller: _controller,
          label: const Text('Categoria'),
          hintText: 'Cerca categoria',
          leadingIcon: const Icon(Icons.search),
          errorText: field.errorText,
          // Occupa tutta la larghezza disponibile, come gli altri campi del form
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          filterCallback: (entries, filter) {
            // Se il testo coincide con la voce già scelta mostra tutta la lista
            if (filter == field.value) return entries;
            return entries
                .where((entry) => matchesSearch(entry.label, filter))
                .toList();
          },
          dropdownMenuEntries: widget.categoryNames
              .map((name) => DropdownMenuEntry<String>(value: name, label: name))
              .toList(),
          onSelected: (value) {
            field.didChange(value);
            widget.onChanged(value);
          },
        );
      },
    );
  }
}
