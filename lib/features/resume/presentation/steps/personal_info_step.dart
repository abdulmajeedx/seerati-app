import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/date_picker_field.dart';
import '../../data/models/resume.dart';

class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({
    super.key,
    required this.draft,
    required this.formKey,
  });

  final Resume draft;
  final GlobalKey<FormState> formKey;

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  PersonalInfo get _info => widget.draft.personalInfo;

  void _deletePhotoFile(String? path) {
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final saved = await File(
        picked.path,
      ).copy('${dir.path}/photo_${widget.draft.id}_$stamp.$ext');
      _deletePhotoFile(_info.photoPath);
      if (!mounted) return;
      setState(() => _info.photoPath = saved.path);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  void _removePhoto() {
    _deletePhotoFile(_info.photoPath);
    setState(() => _info.photoPath = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photoPath = _info.photoPath;
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.resumeLanguage,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
              ButtonSegment(value: 'en', label: Text(l10n.english)),
            ],
            selected: {widget.draft.language},
            onSelectionChanged: (s) =>
                setState(() => widget.draft.language = s.first),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      photoPath != null && File(photoPath).existsSync()
                      ? FileImage(File(photoPath))
                      : null,
                  child: photoPath == null
                      ? const Icon(Icons.person_outline, size: 40)
                      : null,
                ),
                TextButton.icon(
                  icon: Icon(
                    photoPath == null
                        ? Icons.add_a_photo_outlined
                        : Icons.delete_outline,
                  ),
                  label: Text(
                    photoPath == null ? l10n.addPhoto : l10n.removePhoto,
                  ),
                  onPressed: photoPath == null ? _pickPhoto : _removePhoto,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.draft.title,
            decoration: InputDecoration(labelText: l10n.resumeTitle),
            onChanged: (v) => widget.draft.title = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _info.fullName,
            decoration: InputDecoration(labelText: l10n.fullName),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            onChanged: (v) => _info.fullName = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _info.jobTitle,
            decoration: InputDecoration(labelText: l10n.jobTitle),
            onChanged: (v) => _info.jobTitle = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _info.phone,
            decoration: InputDecoration(labelText: l10n.phone),
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: (v) => _info.phone = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _info.email,
            decoration: InputDecoration(labelText: l10n.email),
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            validator: (v) =>
                (v != null &&
                    v.trim().isNotEmpty &&
                    !_emailRegex.hasMatch(v.trim()))
                ? l10n.invalidEmail
                : null,
            onChanged: (v) => _info.email = v,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _info.city,
            decoration: InputDecoration(labelText: l10n.city),
            onChanged: (v) => _info.city = v,
          ),
          const SizedBox(height: 4),
          // Optional extras stay folded away unless already used.
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            shape: const Border(),
            collapsedShape: const Border(),
            initiallyExpanded:
                _info.linkedin.isNotEmpty ||
                _info.website.isNotEmpty ||
                _info.nationality.isNotEmpty ||
                _info.birthDate != null,
            title: Text(l10n.moreDetails),
            children: [
              TextFormField(
                initialValue: _info.linkedin,
                decoration: InputDecoration(
                  labelText: l10n.linkedin,
                  hintText: 'linkedin.com/in/…',
                ),
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                onChanged: (v) => _info.linkedin = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _info.website,
                decoration: InputDecoration(labelText: l10n.website),
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                onChanged: (v) => _info.website = v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _info.nationality,
                decoration: InputDecoration(labelText: l10n.nationality),
                onChanged: (v) => _info.nationality = v,
              ),
              const SizedBox(height: 12),
              DatePickerField(
                label: l10n.birthDate,
                value: _info.birthDate,
                firstDate: DateTime(1940),
                lastDate: DateTime.now(),
                showDay: true,
                onChanged: (d) => setState(() => _info.birthDate = d),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
