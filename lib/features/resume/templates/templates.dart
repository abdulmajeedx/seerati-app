import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../data/models/resume.dart';
import 'pdf_fonts.dart';
import 'resume_strings.dart';

/// Page structure of a template. Each one is a genuinely different layout,
/// not just a recolour.
enum TemplateLayout {
  /// Single column, name over a rule, underlined section titles.
  classic,

  /// Tinted full-height sidebar (photo, contact, skills, languages) beside
  /// the main column.
  sidebar,

  /// Section labels in a narrow side column, hairlines, lots of white space.
  minimal,

  /// Full-bleed coloured banner, timeline entries, filled skill chips.
  banner,
}

class TemplateSpec {
  const TemplateSpec({
    required this.id,
    required this.free,
    required this.accent,
    required this.layout,
  });

  final String id;
  final bool free;
  final PdfColor accent;
  final TemplateLayout layout;

  static const specs = [
    TemplateSpec(
        id: AppConstants.templateClassic,
        free: true,
        accent: PdfColor.fromInt(0xFF37474F),
        layout: TemplateLayout.classic),
    TemplateSpec(
        id: AppConstants.templateModern,
        free: false,
        accent: PdfColor.fromInt(0xFF00696D),
        layout: TemplateLayout.sidebar),
    TemplateSpec(
        id: AppConstants.templateMinimal,
        free: false,
        accent: PdfColor.fromInt(0xFF616161),
        layout: TemplateLayout.minimal),
    TemplateSpec(
        id: AppConstants.templateColorful,
        free: false,
        accent: PdfColor.fromInt(0xFF4527A0),
        layout: TemplateLayout.banner),
  ];

  static TemplateSpec byId(String id) =>
      specs.firstWhere((s) => s.id == id, orElse: () => specs.first);
}

const _sidebarWidth = 185.0;
const _bannerHeight = 150.0;

Future<Uint8List> buildResumePdf(
  Resume resume,
  TemplateSpec spec, {
  required bool watermark,
}) async {
  final fonts = await PdfFonts.load();
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

  final r = _Render(resume, spec, ResumeStrings.of(resume.language), photo);
  final layout = spec.layout;

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        textDirection: isAr ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: switch (layout) {
          TemplateLayout.sidebar => const pw.EdgeInsets.symmetric(vertical: 32),
          TemplateLayout.banner => const pw.EdgeInsets.fromLTRB(36, 0, 36, 36),
          _ => const pw.EdgeInsets.all(36),
        },
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            fit: pw.StackFit.expand,
            children: [
              if (layout == TemplateLayout.sidebar)
                pw.PositionedDirectional(
                  start: 0,
                  top: 0,
                  child: pw.Container(
                    width: _sidebarWidth,
                    height: PdfPageFormat.a4.height,
                    color: _tint(spec.accent, .1),
                  ),
                ),
              if (layout == TemplateLayout.banner && context.pageNumber == 1)
                ..._bannerBackground(spec.accent),
              if (watermark)
                pw.Watermark.text(
                  'Seerati',
                  style: pw.TextStyle(
                    font: fonts.robotoBold,
                    fontSize: 90,
                    color: PdfColors.grey300,
                  ),
                ),
            ],
          ),
        ),
      ),
      // The banner page has no top margin so the band can bleed; later
      // pages still need one.
      header: layout == TemplateLayout.banner
          ? (context) => pw.SizedBox(height: context.pageNumber == 1 ? 0 : 36)
          : null,
      build: (context) => switch (layout) {
        TemplateLayout.classic => r.classic(),
        TemplateLayout.sidebar => r.sidebar(),
        TemplateLayout.minimal => r.minimal(),
        TemplateLayout.banner => r.banner(),
      },
    ),
  );
  return doc.save();
}

/// [c] blended toward white; [amount] 1 = [c], 0 = white.
PdfColor _tint(PdfColor c, double amount) => PdfColor(
      1 - (1 - c.red) * amount,
      1 - (1 - c.green) * amount,
      1 - (1 - c.blue) * amount,
    );

List<pw.Widget> _bannerBackground(PdfColor accent) => [
      pw.Positioned(
        left: 0,
        top: 0,
        child: pw.Container(
          width: PdfPageFormat.a4.width,
          height: _bannerHeight,
          color: accent,
        ),
      ),
      // Decorative disc bleeding off the banner's end corner.
      pw.PositionedDirectional(
        end: -60,
        top: -70,
        child: pw.Container(
          width: 200,
          height: 200,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            color: _tint(accent, .82),
          ),
        ),
      ),
    ];

class _Render {
  _Render(this.resume, this.spec, this.s, this.photo);

  final Resume resume;
  final TemplateSpec spec;
  final ResumeStrings s;
  final pw.MemoryImage? photo;

  PersonalInfo get info => resume.personalInfo;
  PdfColor get accent => spec.accent;
  bool get isAr => resume.isArabic;

  List<String> get contactItems => [
        info.phone,
        info.email,
        info.city,
        _bareLink(info.linkedin),
        _bareLink(info.website),
      ].map((v) => v.trim()).where((v) => v.isNotEmpty).toList();

  /// "Nationality: …", "Date of birth: …" — only the ones filled in.
  List<String> get detailItems => [
        if (info.nationality.trim().isNotEmpty)
          '${s.nationality}: ${info.nationality.trim()}',
        if (info.birthDate != null)
          '${s.birthDate}: ${s.formatFullDate(info.birthDate!)}',
      ];

  /// Links read better on paper without "https://www.".
  static String _bareLink(String url) => url
      .trim()
      .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
      .replaceFirst(RegExp(r'^www\.', caseSensitive: false), '')
      .replaceFirst(RegExp(r'/$'), '');

  // ── Layouts ────────────────────────────────────────────────────────────

  List<pw.Widget> classic() => [
        _classicHeader(),
        for (final (title, body) in _sections(chips: _Chips.outlined)) ...[
          _underlinedTitle(title),
          ...body,
        ],
      ];

  List<pw.Widget> sidebar() {
    pw.Widget side(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 18), child: child);
    pw.Widget main(pw.Widget child) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 26), child: child);

    pw.Widget sideTitle(String t) => side(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold, color: accent)),
        ));

    final sideColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(child: _avatar(96)),
        if (contactItems.isNotEmpty || detailItems.isNotEmpty) ...[
          sideTitle(s.contact),
          for (final item in [...contactItems, ...detailItems])
            side(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(item, style: const pw.TextStyle(fontSize: 8.5)),
            )),
        ],
        if (resume.skills.isNotEmpty) ...[
          sideTitle(s.skills),
          side(_chips(_Chips.white)),
        ],
        if (resume.languages.isNotEmpty) ...[
          sideTitle(s.languages),
          for (final lang in resume.languages)
            side(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(lang.name,
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(s.levelLabel(lang.level),
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey700)),
                ],
              ),
            )),
        ],
      ],
    );

    final mainColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        main(pw.Text(info.fullName,
            style: pw.TextStyle(
                fontSize: 24, fontWeight: pw.FontWeight.bold, color: accent))),
        if (info.jobTitle.trim().isNotEmpty)
          main(pw.Text(info.jobTitle,
              style: const pw.TextStyle(fontSize: 13, color: PdfColors.grey700))),
        for (final (title, body)
            in _sections(skills: false, languages: false)) ...[
          main(_ruledTitle(title)),
          for (final w in body) main(w),
        ],
      ],
    );

    // Partitions always lay out left to right, so flip them for RTL to keep
    // the sidebar on the start side (where the background is drawn).
    final parts = [
      pw.Partition(width: _sidebarWidth, child: sideColumn),
      pw.Partition(child: mainColumn),
    ];
    return [pw.Partitions(children: isAr ? parts.reversed.toList() : parts)];
  }

  List<pw.Widget> minimal() {
    const labelWidth = 92.0;
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(info.fullName,
                    style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900)),
                if (info.jobTitle.trim().isNotEmpty)
                  pw.Text(info.jobTitle,
                      style: pw.TextStyle(fontSize: 12, color: accent)),
                if (contactItems.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 6),
                    child: pw.Text(contactItems.join('   ·   '),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  ),
                if (detailItems.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(detailItems.join('   ·   '),
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                  ),
              ],
            ),
          ),
          if (photo != null)
            pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(photo!,
                  width: 60, height: 60, fit: pw.BoxFit.cover),
            ),
        ],
      ),
      pw.SizedBox(height: 14),
      pw.Container(height: .5, color: PdfColors.grey400),
      // One row per entry (not per section) so long sections can still
      // break across pages; the label sits on the section's first row.
      for (final (title, body) in _sections(chips: _Chips.inline))
        for (final (i, w) in body.indexed)
          pw.Padding(
            padding: pw.EdgeInsets.only(top: i == 0 ? 16 : 0),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: labelWidth,
                  child: i == 0
                      ? pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: accent))
                      : null,
                ),
                pw.Expanded(child: w),
              ],
            ),
          ),
    ];
  }

  List<pw.Widget> banner() {
    final onBanner = _tint(accent, .25);
    return [
      pw.SizedBox(
        height: _bannerHeight,
        child: pw.Row(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: const pw.BoxDecoration(
                  shape: pw.BoxShape.circle, color: PdfColors.white),
              child: _avatar(80, onDark: true),
            ),
            pw.SizedBox(width: 18),
            pw.Expanded(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(info.fullName,
                      style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  if (info.jobTitle.trim().isNotEmpty)
                    pw.Text(info.jobTitle,
                        style: pw.TextStyle(fontSize: 13, color: onBanner)),
                  if (contactItems.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 6),
                      child: pw.Text(contactItems.join('   |   '),
                          style: pw.TextStyle(fontSize: 9, color: onBanner)),
                    ),
                  if (detailItems.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(detailItems.join('   |   '),
                          style: pw.TextStyle(fontSize: 9, color: onBanner)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      pw.SizedBox(height: 6),
      for (final (title, body)
          in _sections(chips: _Chips.filled, timeline: true)) ...[
        _markerTitle(title),
        ...body,
      ],
    ];
  }

  // ── Headers & titles ───────────────────────────────────────────────────

  pw.Widget _classicHeader() => pw.Column(children: [
        pw.Row(
          children: [
            if (photo != null) ...[
              pw.ClipOval(
                child: pw.Image(photo!,
                    width: 64, height: 64, fit: pw.BoxFit.cover),
              ),
              pw.SizedBox(width: 16),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(info.fullName,
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: accent)),
                  if (info.jobTitle.trim().isNotEmpty)
                    pw.Text(info.jobTitle,
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey700)),
                  if (contactItems.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(contactItems.join('   |   '),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ),
                  if (detailItems.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(detailItems.join('   |   '),
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: accent, thickness: 1.2),
      ]);

  /// Photo, or the name's initials when there is none.
  pw.Widget _avatar(double size, {bool onDark = false}) {
    if (photo != null) {
      return pw.ClipOval(
        child: pw.Image(photo!, width: size, height: size, fit: pw.BoxFit.cover),
      );
    }
    final initials = info.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first))
        .join(isAr ? ' ' : '');
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: onDark ? _tint(accent, .15) : accent,
      ),
      child: pw.Text(initials,
          style: pw.TextStyle(
              fontSize: size * .34,
              fontWeight: pw.FontWeight.bold,
              color: onDark ? accent : PdfColors.white)),
    );
  }

  pw.Widget _underlinedTitle(String title) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
            pw.Container(
                width: 42,
                height: 2,
                margin: const pw.EdgeInsets.only(top: 2),
                color: accent),
          ],
        ),
      );

  pw.Widget _ruledTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
        child: pw.Row(
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pw.Container(height: .8, color: _tint(accent, .3))),
          ],
        ),
      );

  pw.Widget _markerTitle(String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
        child: pw.Row(
          children: [
            pw.Container(
              width: 10,
              height: 10,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
          ],
        ),
      );

  // ── Section bodies ─────────────────────────────────────────────────────

  /// Non-empty sections as (title, body widgets). Each body widget is kept
  /// separate so MultiPage can break between them.
  List<(String, List<pw.Widget>)> _sections({
    _Chips chips = _Chips.outlined,
    bool skills = true,
    bool languages = true,
    bool timeline = false,
  }) {
    pw.Widget entry(pw.Widget w) => timeline ? _timeline(w) : w;
    return [
      if (resume.summary.trim().isNotEmpty)
        (
          s.summary,
          [
            pw.Text(resume.summary.trim(),
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.5)),
          ]
        ),
      if (resume.experiences.isNotEmpty)
        (s.experience, [for (final e in resume.experiences) entry(_experience(e))]),
      if (resume.projects.isNotEmpty)
        (s.projects, [for (final p in resume.projects) entry(_project(p))]),
      if (resume.educations.isNotEmpty)
        (s.education, [for (final e in resume.educations) entry(_education(e))]),
      if (skills && resume.skills.isNotEmpty) (s.skills, [_chips(chips)]),
      if (resume.certifications.isNotEmpty)
        (s.certifications, [for (final c in resume.certifications) _credential(c)]),
      if (languages && resume.languages.isNotEmpty)
        (
          s.languages,
          [
            for (final lang in resume.languages)
              _line('${lang.name} — ${s.levelLabel(lang.level)}'),
          ]
        ),
      if (resume.courses.isNotEmpty)
        (s.courses, [for (final c in resume.courses) _credential(c)]),
    ];
  }

  /// A course or certification: "Name — Issuer — Year".
  pw.Widget _credential(CourseItem c) => _line([
        c.name,
        if (c.issuer.trim().isNotEmpty) c.issuer,
        if (c.year.trim().isNotEmpty) c.year,
      ].join(' — '));

  pw.Widget _project(ProjectItem p) => _entry(
        title: p.name,
        subtitle: _bareLink(p.link),
        dates: '',
        description: p.description,
      );

  pw.Widget _line(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );

  /// A vertical rule on the start side joining a section's entries.
  pw.Widget _timeline(pw.Widget child) {
    final side = pw.BorderSide(color: _tint(accent, .35), width: 1.5);
    return pw.Container(
      margin: const pw.EdgeInsetsDirectional.only(start: 4),
      padding: const pw.EdgeInsetsDirectional.only(start: 12, bottom: 2),
      decoration: pw.BoxDecoration(
        border: isAr ? pw.Border(right: side) : pw.Border(left: side),
      ),
      child: child,
    );
  }

  pw.Widget _chips(_Chips style) {
    if (style == _Chips.inline) {
      return pw.Text(resume.skills.join('  ·  '),
          style: const pw.TextStyle(fontSize: 10));
    }
    return pw.Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final skill in resume.skills)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(
              color: switch (style) {
                _Chips.filled => accent,
                _Chips.white => PdfColors.white,
                _ => null,
              },
              border: style == _Chips.outlined
                  ? pw.Border.all(color: accent, width: .8)
                  : null,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(skill,
                style: pw.TextStyle(
                    fontSize: style == _Chips.white ? 8.5 : 9,
                    color: style == _Chips.filled ? PdfColors.white : null)),
          ),
      ],
    );
  }

  pw.Widget _experience(ExperienceItem e) => _entry(
        title: e.jobTitle,
        subtitle: [e.company, e.city]
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .join(' · '),
        dates: _range(e.startDate, e.endDate, current: e.isCurrent),
        description: e.description,
      );

  pw.Widget _education(EducationItem e) => _entry(
        title: e.degree,
        subtitle: [e.institution, e.city]
            .map((v) => v.trim())
            .where((v) => v.isNotEmpty)
            .join(' · '),
        dates: _range(e.startDate, e.endDate),
        description: e.description,
      );

  String _range(DateTime? start, DateTime? end, {bool current = false}) {
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
                style: pw.TextStyle(
                    fontSize: 10,
                    color: spec.layout == TemplateLayout.classic
                        ? PdfColors.grey800
                        : accent)),
          if (description.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(description.trim(),
                  style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.2)),
            ),
        ],
      ),
    );
  }
}

enum _Chips { outlined, filled, white, inline }
