import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/date_picker_field.dart';
import '../../data/models/resume.dart';

class EducationStep extends StatefulWidget {
  const EducationStep({super.key, required this.draft});

  final Resume draft;

  @override
  State<EducationStep> createState() => _EducationStepState();
}

class _EducationStepState extends State<EducationStep> {
  Future<void> _openEditor({EducationItem? item}) async {
    final result = await showModalBottomSheet<EducationItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EducationSheet(item: item),
    );
    if (result == null) return;
    setState(() {
      final items = widget.draft.educations;
      if (item == null) {
        items.add(result);
      } else {
        items[items.indexOf(item)] = result;
      }
    });
  }

  String _dates(BuildContext context, EducationItem e) {
    final locale = Localizations.localeOf(context).toString();
    final fmt = DateFormat.yMMM(locale);
    final start = e.startDate == null ? '' : fmt.format(e.startDate!);
    final end = e.endDate == null ? '' : fmt.format(e.endDate!);
    if (start.isEmpty) return end;
    if (end.isEmpty) return start;
    return '$start — $end';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = widget.draft.educations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noEducationYet,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        for (final (i, e) in items.indexed)
          Card(
            margin: const EdgeInsetsDirectional.only(bottom: 8),
            child: ListTile(
              title: Text(e.degree),
              subtitle: Text([e.institution, _dates(context, e)]
                  .where((s) => s.isNotEmpty)
                  .join('\n')),
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
          label: Text(l10n.addEducation),
          onPressed: () => _openEditor(),
        ),
      ],
    );
  }
}

class _EducationSheet extends StatefulWidget {
  const _EducationSheet({this.item});

  final EducationItem? item;

  @override
  State<_EducationSheet> createState() => _EducationSheetState();
}

class _EducationSheetState extends State<_EducationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final EducationItem _item = widget.item?.copy() ?? EducationItem();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
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
                widget.item == null ? l10n.addEducation : l10n.edit,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _item.degree,
                decoration: InputDecoration(labelText: l10n.degree),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                onChanged: (v) => _item.degree = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _item.institution,
                decoration: InputDecoration(labelText: l10n.institution),
                onChanged: (v) => _item.institution = v,
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
                      onChanged: (d) => setState(() => _item.endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
