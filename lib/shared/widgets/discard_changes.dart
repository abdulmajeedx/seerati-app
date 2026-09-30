import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'dialog_action_style.dart';

/// Asks before throwing away unsaved edits. True means leave.
Future<bool> confirmDiscardChanges(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.edit_note_outlined),
      title: Text(l10n.discardChangesTitle),
      content: Text(l10n.discardChangesMsg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.discard),
        ),
        FilledButton(
          style: dialogActionStyle,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.keepEditing),
        ),
      ],
    ),
  );
  return discard ?? false;
}
