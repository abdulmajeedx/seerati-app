import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/ai_button.dart';
import '../../data/models/resume.dart';

class SummaryStep extends StatefulWidget {
  const SummaryStep({super.key, required this.draft});

  final Resume draft;

  @override
  State<SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<SummaryStep> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.draft.summary);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: l10n.summary,
            hintText: l10n.summaryHint,
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          maxLength: 600,
          onChanged: (v) => widget.draft.summary = v,
        ),
        AiButton(
          label: l10n.aiImprove,
          request: (client) => client.improveSummary(
            language: widget.draft.language,
            jobTitle: widget.draft.personalInfo.jobTitle,
            skills: widget.draft.skills,
            currentSummary: _controller.text,
          ),
          onResult: (text) {
            _controller.text = text;
            widget.draft.summary = text;
          },
        ),
      ],
    );
  }
}
