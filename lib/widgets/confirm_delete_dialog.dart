import 'package:flutter/material.dart';

/// Shows a confirmation dialog before deleting an item.
///
/// Returns `true` if the user confirms, `false` if they cancel.
/// [itemDescription] is inserted in the message ("delete {itemDescription}?").
Future<bool?> showConfirmDeleteDialog(
  BuildContext context,
  String itemDescription,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Conferma eliminazione'),
      content: Text('Sei sicuro di voler eliminare $itemDescription?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
}
