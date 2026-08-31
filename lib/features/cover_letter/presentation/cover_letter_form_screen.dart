import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/cover_letter.dart';
import '../services/cover_letter_generator.dart';
import 'cover_letter_editor_screen.dart';

class CoverLetterFormScreen extends StatefulWidget {
  const CoverLetterFormScreen({super.key});

  @override
  State<CoverLetterFormScreen> createState() => _CoverLetterFormScreenState();
}

class _CoverLetterFormScreenState extends State<CoverLetterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sender = TextEditingController();
  final _recipient = TextEditingController();
  final _company = TextEditingController();
  final _jobTitle = TextEditingController();
  String _language = 'ar';

  @override
  void dispose() {
    _sender.dispose();
    _recipient.dispose();
    _company.dispose();
    _jobTitle.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final letter = CoverLetter(
      id: const Uuid().v4(),
      language: _language,
      senderName: _sender.text.trim(),
      recipientName: _recipient.text.trim(),
      companyName: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      createdAt: now,
      updatedAt: now,
    );
    letter.body = CoverLetterGenerator.generate(letter);
    await StorageService.coverLetters.put(letter.id, letter);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => CoverLetterEditorScreen(letter: letter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newCoverLetter)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.language, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
                ButtonSegment(value: 'en', label: Text(l10n.english)),
              ],
              selected: {_language},
              onSelectionChanged: (s) => setState(() => _language = s.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sender,
              decoration: InputDecoration(labelText: l10n.senderName),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _jobTitle,
              decoration: InputDecoration(labelText: l10n.jobTitle),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _company,
              decoration: InputDecoration(labelText: l10n.companyName),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipient,
              decoration: InputDecoration(labelText: l10n.recipientName),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(l10n.generate),
              onPressed: _generate,
            ),
          ],
        ),
      ),
    );
  }
}
