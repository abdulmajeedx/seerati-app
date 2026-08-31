import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../resume/templates/pdf_fonts.dart';
import '../data/models/cover_letter.dart';

abstract final class CoverLetterPdf {
  static Future<Uint8List> build(CoverLetter letter,
      {required bool watermark}) async {
    final fonts = await PdfFonts.load();
    final isAr = letter.language == 'ar';
    final theme = pw.ThemeData.withFont(
      base: isAr ? fonts.cairo : fonts.roboto,
      bold: isAr ? fonts.cairoBold : fonts.robotoBold,
      fontFallback: [fonts.cairo, fonts.roboto],
    );
    final accent = PdfColor.fromInt(0xFF37474F);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: theme,
          textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          margin: const pw.EdgeInsets.all(48),
          buildBackground: watermark
              ? (context) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Watermark.text(
                      'Seerati',
                      style: pw.TextStyle(
                        font: fonts.robotoBold,
                        fontSize: 90,
                        color: PdfColors.grey300,
                      ),
                    ),
                  )
              : null,
        ),
        build: (context) => [
          if (letter.senderName.trim().isNotEmpty) ...[
            pw.Text(
              letter.senderName,
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: accent),
            ),
            if (letter.jobTitle.trim().isNotEmpty)
              pw.Text(letter.jobTitle,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 6),
            pw.Divider(color: accent, thickness: 1),
            pw.SizedBox(height: 18),
          ],
          pw.Text(letter.body,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
        ],
      ),
    );
    return doc.save();
  }

  static Future<void> share(CoverLetter letter,
      {required bool watermark}) async {
    final bytes = await build(letter, watermark: watermark);
    await Printing.sharePdf(bytes: bytes, filename: 'cover_letter.pdf');
  }
}
