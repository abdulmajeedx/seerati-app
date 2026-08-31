import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/ai_button.dart';
import '../data/models/cover_letter.dart';
import 'cover_letter_editor_screen.dart';

class AiCoverLetterScreen extends StatefulWidget {
  const AiCoverLetterScreen({super.key});

  @override
  State<AiCoverLetterScreen> createState() => _AiCoverLetterScreenState();
}

class _AiCoverLetterScreenState extends State<AiCoverLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sender = TextEditingController();
  final _company = TextEditingController();
  final _jobTitle = TextEditingController();
  final _jobAd = TextEditingController();
  String _language = 'ar';

  @override
  void dispose() {
    _sender.dispose();
    _company.dispose();
    _jobTitle.dispose();
    _jobAd.dispose();
    super.dispose();
  }

  Future<void> _open(String body) async {
    final now = DateTime.now();
    final letter = CoverLetter(
      id: const Uuid().v4(),
      language: _language,
      senderName: _sender.text.trim(),
      companyName: _company.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    await StorageService.coverLetters.put(letter.id, letter);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => CoverLetterEditorScreen(letter: letter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.coverLetterFromAd)),
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
              controller: _jobAd,
              decoration: InputDecoration(
                labelText: l10n.jobAd,
                hintText: l10n.jobAdHint,
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 6000,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
            ),
            const SizedBox(height: 8),
            AiButton(
              label: l10n.generateWithAi,
              validate: () => _formKey.currentState!.validate(),
              request: (client) {
                return client.coverLetterFromAd(
                  language: _language,
                  applicantName: _sender.text.trim(),
                  jobTitle: _jobTitle.text.trim(),
                  company: _company.text.trim(),
                  jobAd: _jobAd.text.trim(),
                  resumeSummary: _latestResumeSummary(),
                );
              },
              onResult: _open,
            ),
          ],
        ),
      ),
    );
  }

  /// Gives the model context from the user's most recently edited resume.
  String _latestResumeSummary() {
    final resumes = StorageService.resumes.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return resumes.isEmpty ? '' : resumes.first.summary;
  }
}
