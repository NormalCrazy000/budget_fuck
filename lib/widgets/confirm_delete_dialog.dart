import 'package:flutter/material.dart';

/// Mostra un dialog di conferma prima di eliminare un elemento.
///
/// Restituisce `true` se l'utente conferma, `false` se annulla.
/// [itemDescription] viene inserito nel messaggio: "Sei sicuro di voler eliminare {itemDescription}?"
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
