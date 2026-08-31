import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/providers/premium_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/resume.dart';
import '../services/pdf_service.dart';

class ResumePreviewScreen extends ConsumerWidget {
  const ResumePreviewScreen({super.key, required this.resume});

  final Resume resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.preview)),
      body: PdfPreview(
        build: (format) => PdfService.build(resume, watermark: !premium),
        pdfFileName: '${resume.title}.pdf',
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) =>
            Center(child: Text(l10n.errorGeneric)),
      ),
    );
  }
}
