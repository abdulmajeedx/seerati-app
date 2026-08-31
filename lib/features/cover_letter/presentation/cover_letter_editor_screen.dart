import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/providers/premium_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/cover_letter.dart';
import '../services/cover_letter_pdf.dart';

class CoverLetterEditorScreen extends ConsumerStatefulWidget {
  const CoverLetterEditorScreen({super.key, required this.letter});

  final CoverLetter letter;

  @override
  ConsumerState<CoverLetterEditorScreen> createState() =>
      _CoverLetterEditorScreenState();
}

class _CoverLetterEditorScreenState
    extends ConsumerState<CoverLetterEditorScreen> {
  late final TextEditingController _body =
      TextEditingController(text: widget.letter.body);

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    widget.letter
      ..body = _body.text
      ..updatedAt = DateTime.now();
    await StorageService.coverLetters.put(widget.letter.id, widget.letter);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.coverLetterSaved)));
  }

  void _preview() {
    widget.letter.body = _body.text;
    final premium = ref.read(premiumProvider);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CoverLetterPreviewScreen(
            letter: widget.letter, watermark: !premium),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.letter.companyName.trim().isNotEmpty
        ? widget.letter.companyName
        : l10n.coverLetter;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: l10n.save,
            onPressed: _save,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.preview,
            onPressed: _preview,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _body,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            labelText: l10n.letterBody,
            alignLabelWithHint: true,
          ),
        ),
      ),
    );
  }
}

class _CoverLetterPreviewScreen extends StatelessWidget {
  const _CoverLetterPreviewScreen(
      {required this.letter, required this.watermark});

  final CoverLetter letter;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preview)),
      body: PdfPreview(
        build: (format) => CoverLetterPdf.build(letter, watermark: watermark),
        pdfFileName: 'cover_letter.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => Center(child: Text(l10n.errorGeneric)),
      ),
    );
  }
}
