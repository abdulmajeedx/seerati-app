import 'package:flutter/material.dart';

import '../../../../core/utils/language_levels.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/resume.dart';
import '../../../../shared/widgets/dialog_action_style.dart';

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

  Future<void> _addCourse({bool certification = false}) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<CourseItem>(
      context: context,
      builder: (_) => certification
          ? _CourseDialog(
              title: l10n.addCertification,
              nameLabel: l10n.certificationName,
            )
          : _CourseDialog(title: l10n.addCourse, nameLabel: l10n.courses),
    );
    if (result == null) return;
    setState(
      () => (certification ? widget.draft.certifications : widget.draft.courses)
          .add(result),
    );
  }

  Future<void> _addProject() async {
    final result = await showDialog<ProjectItem>(
      context: context,
      builder: (_) => const _ProjectDialog(),
    );
    if (result != null) setState(() => widget.draft.projects.add(result));
  }

  Widget _credentialTile(List<CourseItem> list, int i, AppLocalizations l10n) {
    final c = list[i];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(c.name),
      subtitle: Text([c.issuer, c.year].where((s) => s.isNotEmpty).join(' · ')),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.delete,
        onPressed: () => setState(() => list.removeAt(i)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold);
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
        Text(l10n.certifications, style: titleStyle),
        for (var i = 0; i < widget.draft.certifications.length; i++)
          _credentialTile(widget.draft.certifications, i, l10n),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCertification),
          onPressed: () => _addCourse(certification: true),
        ),
        const SizedBox(height: 24),
        Text(l10n.courses, style: titleStyle),
        for (var i = 0; i < widget.draft.courses.length; i++)
          _credentialTile(widget.draft.courses, i, l10n),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addCourse),
          onPressed: _addCourse,
        ),
        const SizedBox(height: 24),
        Text(l10n.projects, style: titleStyle),
        for (final (i, project) in widget.draft.projects.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(project.name),
            subtitle: project.link.isEmpty
                ? null
                : Text(project.link, textDirection: TextDirection.ltr),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.delete,
              onPressed: () =>
                  setState(() => widget.draft.projects.removeAt(i)),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addProject),
          onPressed: _addProject,
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
                  child: Text(LanguageLevels.label(level, l10n)),
                ),
            ],
            onChanged: (v) =>
                setState(() => _level = v ?? LanguageLevels.intermediate),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: dialogActionStyle,
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _CourseDialog extends StatefulWidget {
  const _CourseDialog({required this.title, required this.nameLabel});

  final String title;
  final String nameLabel;

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
    Navigator.of(context).pop(
      CourseItem(
        name: name,
        issuer: _issuer.text.trim(),
        year: _year.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: widget.nameLabel),
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: dialogActionStyle,
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _ProjectDialog extends StatefulWidget {
  const _ProjectDialog();

  @override
  State<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<_ProjectDialog> {
  final _name = TextEditingController();
  final _link = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _link.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      ProjectItem(
        name: name,
        link: _link.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addProject),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.projectName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: l10n.projectLink),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.description,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: dialogActionStyle,
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
