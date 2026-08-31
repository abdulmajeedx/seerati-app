import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/models/resume.dart';

class SkillsStep extends StatefulWidget {
  const SkillsStep({super.key, required this.draft});

  final Resume draft;

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final skill = _controller.text.trim();
    if (skill.isEmpty || widget.draft.skills.contains(skill)) return;
    setState(() => widget.draft.skills.add(skill));
    _controller.clear();
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
            labelText: l10n.addSkill,
            hintText: l10n.skillsHint,
            suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: _add),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final skill in widget.draft.skills)
              InputChip(
                label: Text(skill),
                onDeleted: () =>
                    setState(() => widget.draft.skills.remove(skill)),
              ),
          ],
        ),
      ],
    );
  }
}
