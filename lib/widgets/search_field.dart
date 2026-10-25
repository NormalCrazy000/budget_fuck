import 'package:flutter/material.dart';

/// Reusable search bar for the top of lists.
///
/// Shows a magnifier icon on the left and, when the field is not empty,
/// an "X" button on the right to clear it. On every change (including the
/// "X" click) it calls [onChanged] with the current text.
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
    // setState to hide the "X" button
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
          // setState to show/hide the "X" button
          setState(() {});
        },
      ),
    );
  }
}
