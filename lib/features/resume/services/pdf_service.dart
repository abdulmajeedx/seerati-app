import 'dart:typed_data';

import 'package:printing/printing.dart';

import '../data/models/resume.dart';
import '../templates/templates.dart';

abstract final class PdfService {
  static Future<Uint8List> build(Resume resume, {required bool watermark}) {
    return buildResumePdf(
      resume,
      TemplateSpec.byId(resume.templateId),
      watermark: watermark,
    );
  }

  static Future<void> share(Resume resume, {required bool watermark}) async {
    final bytes = await build(resume, watermark: watermark);
    await Printing.sharePdf(bytes: bytes, filename: '${resume.title}.pdf');
  }
}
