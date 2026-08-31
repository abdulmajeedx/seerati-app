import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/resume.dart';

class SummaryStep extends StatelessWidget {
  const SummaryStep({super.key, required this.draft});

  final Resume draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      initialValue: draft.summary,
      decoration: InputDecoration(
        labelText: l10n.summary,
        hintText: l10n.summaryHint,
        alignLabelWithHint: true,
      ),
      maxLines: 6,
      maxLength: 600,
      onChanged: (v) => draft.summary = v,
    );
  }
}
