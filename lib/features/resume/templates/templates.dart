import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../data/models/resume.dart';
import 'pdf_fonts.dart';
import 'resume_strings.dart';

class TemplateSpec {
  const TemplateSpec({
    required this.id,
    required this.free,
    required this.accent,
    this.filledHeader = false,
    this.showTitleBar = true,
  });

  final String id;
  final bool free;
  final PdfColor accent;
  final bool filledHeader;
  final bool showTitleBar;

  static const specs = [
    TemplateSpec(
        id: AppConstants.templateClassic,
        free: true,
        accent: PdfColor.fromInt(0xFF37474F)),
    TemplateSpec(
        id: AppConstants.templateModern,
        free: false,
        accent: PdfColor.fromInt(0xFF00696D)),
    TemplateSpec(
        id: AppConstants.templateMinimal,
        free: false,
        accent: PdfColor.fromInt(0xFF616161),
        showTitleBar: false),
    TemplateSpec(
        id: AppConstants.templateColorful,
        free: false,
        accent: PdfColor.fromInt(0xFF4527A0),
        filledHeader: true),
  ];

  static TemplateSpec byId(String id) =>
      specs.firstWhere((s) => s.id == id, orElse: () => specs.first);
}

Future<Uint8List> buildResumePdf(
  Resume resume,
  TemplateSpec spec, {
  required bool watermark,
}) async {
  final fonts = await PdfFonts.load();
  final s = ResumeStrings.of(resume.language);
  final isAr = resume.isArabic;
  final base = isAr ? fonts.cairo : fonts.roboto;
  final bold = isAr ? fonts.cairoBold : fonts.robotoBold;
  final theme = pw.ThemeData.withFont(
    base: base,
    bold: bold,
    fontFallback: [fonts.cairo, fonts.roboto],
  );

  pw.MemoryImage? photo;
  final photoPath = resume.personalInfo.photoPath;
  if (photoPath != null && File(photoPath).existsSync()) {
    photo = pw.MemoryImage(File(photoPath).readAsBytesSync());
  }

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(36),
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
        _header(resume, spec, photo),
        if (resume.summary.trim().isNotEmpty) ...[
          _sectionTitle(s.summary, spec),
          pw.Text(resume.summary.trim(), style: const pw.TextStyle(fontSize: 10)),
        ],
        if (resume.experiences.isNotEmpty) ...[
          _sectionTitle(s.experience, spec),
          for (final e in resume.experiences) _experienceEntry(e, s),
        ],
        if (resume.educations.isNotEmpty) ...[
          _sectionTitle(s.education, spec),
          for (final e in resume.educations) _educationEntry(e, s),
        ],
        if (resume.skills.isNotEmpty) ...[
          _sectionTitle(s.skills, spec),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final skill in resume.skills)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: spec.accent, width: .8),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(skill,
                      style: const pw.TextStyle(fontSize: 9)),
                ),
            ],
          ),
        ],
        if (resume.languages.isNotEmpty) ...[
          _sectionTitle(s.languages, spec),
          for (final lang in resume.languages)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text('${lang.name} — ${s.levelLabel(lang.level)}',
                  style: const pw.TextStyle(fontSize: 10)),
            ),
        ],
        if (resume.courses.isNotEmpty) ...[
          _sectionTitle(s.courses, spec),
          for (final c in resume.courses)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                [
                  c.name,
                  if (c.issuer.trim().isNotEmpty) c.issuer,
                  if (c.year.trim().isNotEmpty) c.year,
                ].join(' — '),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        ],
      ],
    ),
  );
  return doc.save();
}

pw.Widget _header(Resume resume, TemplateSpec spec, pw.MemoryImage? photo) {
  final info = resume.personalInfo;
  final contact = [info.phone, info.email, info.city]
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .join('   |   ');
  final onFilled = spec.filledHeader ? PdfColors.white : null;

  final content = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (photo != null) ...[
        pw.ClipOval(
          child: pw.Image(photo, width: 64, height: 64, fit: pw.BoxFit.cover),
        ),
        pw.SizedBox(width: 16),
      ],
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              info.fullName,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: onFilled ?? spec.accent,
              ),
            ),
            if (info.jobTitle.trim().isNotEmpty)
              pw.Text(info.jobTitle,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: onFilled ?? PdfColors.grey700)),
            if (contact.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(contact,
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: onFilled ?? PdfColors.grey700)),
              ),
          ],
        ),
      ),
    ],
  );

  if (spec.filledHeader) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: spec.accent,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: content,
    );
  }
  return pw.Column(children: [
    content,
    pw.SizedBox(height: 8),
    pw.Divider(color: spec.accent, thickness: 1.2),
  ]);
}

pw.Widget _sectionTitle(String title, TemplateSpec spec) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: spec.accent)),
        if (spec.showTitleBar)
          pw.Container(
              width: 42,
              height: 2,
              margin: const pw.EdgeInsets.only(top: 2),
              color: spec.accent),
      ],
    ),
  );
}

String _range(DateTime? start, DateTime? end, ResumeStrings s,
    {bool current = false}) {
  final a = start == null ? '' : s.formatDate(start);
  final b = current ? s.present : (end == null ? '' : s.formatDate(end));
  if (a.isEmpty) return b;
  if (b.isEmpty) return a;
  return '$a — $b';
}

pw.Widget _entry({
  required String title,
  required String subtitle,
  required String dates,
  required String description,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ),
            if (dates.isNotEmpty)
              pw.Text(dates,
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
          ],
        ),
        if (subtitle.isNotEmpty)
          pw.Text(subtitle,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey800)),
        if (description.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(description.trim(),
                style: const pw.TextStyle(fontSize: 9.5)),
          ),
      ],
    ),
  );
}

pw.Widget _experienceEntry(ExperienceItem e, ResumeStrings s) => _entry(
      title: e.jobTitle,
      subtitle: [e.company, e.city]
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .join(' · '),
      dates: _range(e.startDate, e.endDate, s, current: e.isCurrent),
      description: e.description,
    );

pw.Widget _educationEntry(EducationItem e, ResumeStrings s) => _entry(
      title: e.degree,
      subtitle: [e.institution, e.city]
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .join(' · '),
      dates: _range(e.startDate, e.endDate, s),
      description: e.description,
    );
