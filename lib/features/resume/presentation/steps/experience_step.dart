import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/date_picker_field.dart';
import '../../data/models/resume.dart';

class ExperienceStep extends StatefulWidget {
  const ExperienceStep({super.key, required this.draft});

  final Resume draft;

  @override
  State<ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends State<ExperienceStep> {
  Future<void> _openEditor({ExperienceItem? item}) async {
    final result = await showModalBottomSheet<ExperienceItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ExperienceSheet(item: item),
    );
    if (result == null) return;
    setState(() {
      final items = widget.draft.experiences;
      if (item == null) {
        items.add(result);
      } else {
        items[items.indexOf(item)] = result;
      }
    });
  }

  String _dates(BuildContext context, ExperienceItem e) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMM(locale);
    final start = e.startDate == null ? '' : fmt.format(e.startDate!);
    final end = e.isCurrent
        ? l10n.present
        : (e.endDate == null ? '' : fmt.format(e.endDate!));
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start — $end';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = widget.draft.experiences;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noExperienceYet,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        for (final (i, e) in items.indexed)
          Card(
            margin: const EdgeInsetsDirectional.only(bottom: 8),
            child: ListTile(
              title: Text(e.jobTitle),
              subtitle: Text(
                  [e.company, _dates(context, e)].where((s) => s.isNotEmpty).join('\n')),
              onTap: () => _openEditor(item: e),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.delete,
                onPressed: () => setState(() => items.removeAt(i)),
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(l10n.addExperience),
          onPressed: () => _openEditor(),
        ),
      ],
    );
  }
}

class _ExperienceSheet extends StatefulWidget {
  const _ExperienceSheet({this.item});

  final ExperienceItem? item;

  @override
  State<_ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends State<_ExperienceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final ExperienceItem _item = widget.item?.copy() ?? ExperienceItem();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_item.isCurrent) _item.endDate = null;
    final l10n = AppLocalizations.of(context);
    if (_item.startDate != null &&
        _item.endDate != null &&
        _item.endDate!.isBefore(_item.startDate!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.endBeforeStart)));
      return;
    }
    Navigator.of(context).pop(_item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.item == null ? l10n.addExperience : l10n.edit,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _item.jobTitle,
                decoration: InputDecoration(labelText: l10n.jobTitle),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                onChanged: (v) => _item.jobTitle = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _item.company,
                decoration: InputDecoration(labelText: l10n.company),
                onChanged: (v) => _item.company = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _item.city,
                decoration: InputDecoration(labelText: l10n.city),
                onChanged: (v) => _item.city = v,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DatePickerField(
                      label: l10n.startDate,
                      value: _item.startDate,
                      onChanged: (d) => setState(() => _item.startDate = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DatePickerField(
                      label: l10n.endDate,
                      value: _item.endDate,
                      enabled: !_item.isCurrent,
                      onChanged: (d) => setState(() => _item.endDate = d),
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                value: _item.isCurrent,
                title: Text(l10n.currentJob),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _item.isCurrent = v ?? false),
              ),
              TextFormField(
                initialValue: _item.description,
                decoration: InputDecoration(
                    labelText: l10n.description, alignLabelWithHint: true),
                maxLines: 3,
                onChanged: (v) => _item.description = v,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }
}
