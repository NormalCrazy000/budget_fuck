import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
      title: Text(AppLocalizations.of(context).confirmDeletion),
      content: Text(
        AppLocalizations.of(context).confirmDeletionMessage(itemDescription),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(AppLocalizations.of(context).delete),
        ),
      ],
    ),
  );
}
