import 'package:flutter/material.dart';

/// Barra di ricerca riutilizzabile da mettere in cima alle liste.
///
/// Mostra un'icona lente a sinistra e, quando il campo non è vuoto,
/// un pulsante "X" a destra per cancellare il testo. Ad ogni modifica
/// (incluso il click sulla X) chiama [onChanged] con il testo corrente.
class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    // setState per nascondere il pulsante "X"
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Cancella ricerca',
                  onPressed: _clear,
                ),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          widget.onChanged(value);
          // setState per mostrare/nascondere il pulsante "X"
          setState(() {});
        },
      ),
    );
  }
}
