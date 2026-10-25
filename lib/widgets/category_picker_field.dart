import 'package:flutter/material.dart';
import '../utils/search.dart';

/// Searchable category picker, to be used inside a [Form].
///
/// Replaces the classic dropdown: the user can type in the field and the
/// list only shows the categories containing the typed text (ignoring case
/// and accents, see [matchesSearch]).
///
/// Validation fails unless an entry was picked from the list: typed text
/// alone is not enough.
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

  /// If the user edits the text after picking a category, the choice is
  /// cleared: the value must always come from the list.
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
          // Take the full available width, like the other form fields
          expandedInsets: EdgeInsets.zero,
          enableFilter: true,
          requestFocusOnTap: true,
          filterCallback: (entries, filter) {
            // If the text matches the picked entry, show the whole list
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
