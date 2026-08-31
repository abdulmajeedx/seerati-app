import 'package:flutter/material.dart';

import '../../../../core/utils/language_levels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/resume.dart';

class ExtrasStep extends StatefulWidget {
  const ExtrasStep({super.key, required this.draft});

  final Resume draft;

  @override
  State<ExtrasStep> createState() => _ExtrasStepState();
}

class _ExtrasStepState extends State<ExtrasStep> {
  Future<void> _addLanguage() async {
    final result = await showDialog<LanguageItem>(
      context: context,
      builder: (_) => const _LanguageDialog(),
    );
    if (result != null) setState(() => widget.draft.languages.add(result));
  }

  Future<void> _addCourse() async {
    final result = await showDialog<CourseItem>(
      context: context,
      builder: (_) => const _CourseDialog(),
    );
    if (result != null) setState(() => widget.draft.courses.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(context)
        .textTheme
        .titleSmall
        ?.copyWith(fontWeight: FontWeight.bold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.languagesSection, style: titleStyle),
        for (final (i, lang) in widget.draft.languages.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(lang.name),
            subtitle: Text(LanguageLevels.label(lang.level, l10n)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: () =>
                  setState(() => widget.draft.languages.removeAt(i)),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addLanguage),
          onPressed: _addLanguage,
        ),
        const SizedBox(height: 24),
        Text(l10n.courses, style: titleStyle),
        for (final (i, course) in widget.draft.courses.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(course.name),
            subtitle: Text([course.issuer, course.year]
                .where((s) => s.isNotEmpty)
                .join(' · ')),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: () => setState(() => widget.draft.courses.removeAt(i)),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCourse),
          onPressed: _addCourse,
        ),
      ],
    );
  }
}

class _LanguageDialog extends StatefulWidget {
  const _LanguageDialog();

  @override
  State<_LanguageDialog> createState() => _LanguageDialogState();
}

class _LanguageDialogState extends State<_LanguageDialog> {
  final _controller = TextEditingController();
  String _level = LanguageLevels.intermediate;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(LanguageItem(name: name, level: _level));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.language),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _level,
            decoration: InputDecoration(labelText: l10n.level),
            items: [
              for (final level in LanguageLevels.all)
                DropdownMenuItem(
                    value: level,
                    child: Text(LanguageLevels.label(level, l10n))),
            ],
            onChanged: (v) =>
                setState(() => _level = v ?? LanguageLevels.intermediate),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}

class _CourseDialog extends StatefulWidget {
  const _CourseDialog();

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  final _name = TextEditingController();
  final _issuer = TextEditingController();
  final _year = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(CourseItem(
      name: name,
      issuer: _issuer.text.trim(),
      year: _year.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addCourse),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.courses),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _issuer,
            decoration: InputDecoration(labelText: l10n.issuer),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _year,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l10n.year),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
