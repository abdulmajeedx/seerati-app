import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../l10n/app_localizations.dart';
import '../../data/models/resume.dart';
import '../../data/resume_completeness.dart';
import '../../templates/templates.dart';

enum ResumeCardAction { edit, preview, changeTemplate, delete }

/// A saved resume on the home list: a miniature of its template, the title
/// and job, when it was last edited, and how complete it is.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.resume,
    required this.onTap,
    required this.onAction,
  });

  final Resume resume;
  final VoidCallback onTap;
  final ValueChanged<ResumeCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final spec = TemplateSpec.byId(resume.templateId);
    final progress = resume.completeness;
    final job = resume.personalInfo.jobTitle.trim();
    final percent = NumberFormat.percentPattern(locale).format(progress);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 4, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Miniature(spec: spec),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.title,
                      style: text.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        if (job.isNotEmpty) job,
                        DateFormat.yMMMd(locale).format(resume.updatedAt),
                      ].join(' · '),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: scheme.surfaceContainerHighest,
                              color: progress >= 1
                                  ? scheme.primary
                                  : scheme.tertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.resumeProgress(percent),
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<ResumeCardAction>(
                onSelected: onAction,
                itemBuilder: (context) => [
                  _item(ResumeCardAction.edit, Icons.edit_outlined, l10n.edit),
                  _item(
                    ResumeCardAction.preview,
                    Icons.picture_as_pdf_outlined,
                    l10n.preview,
                  ),
                  _item(
                    ResumeCardAction.changeTemplate,
                    Icons.dashboard_customize_outlined,
                    l10n.changeTemplate,
                  ),
                  _item(
                    ResumeCardAction.delete,
                    Icons.delete_outline,
                    l10n.delete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<ResumeCardAction> _item(
    ResumeCardAction value,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: value,
    child: ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
    ),
  );
}

/// A tiny page in the resume's template: its accent colour and its layout's
/// silhouette (sidebar, banner, side labels or plain column).
class _Miniature extends StatelessWidget {
  const _Miniature({required this.spec});

  final TemplateSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Color(spec.accent.toInt() | 0xFF000000);
    const lineColor = Color(0xFFD7DCDC);
    Widget line(double widthFactor) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
    final lines = [line(1), line(.8), line(1), line(.6)];

    final body = switch (spec.layout) {
      TemplateLayout.sidebar => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 13, color: accent.withValues(alpha: .18)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                children: [
                  Container(height: 4, color: accent),
                  const SizedBox(height: 5),
                  ...lines,
                ],
              ),
            ),
          ),
        ],
      ),
      TemplateLayout.banner => Column(
        children: [
          Container(height: 14, color: accent),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(children: lines),
          ),
        ],
      ),
      TemplateLayout.minimal => Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            line(.7),
            const SizedBox(height: 3),
            for (var i = 0; i < 4; i++)
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 2.5,
                    margin: const EdgeInsetsDirectional.only(end: 3, bottom: 3),
                    color: i.isEven ? accent : Colors.transparent,
                  ),
                  Expanded(child: line(1)),
                ],
              ),
          ],
        ),
      ),
      TemplateLayout.classic => Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          children: [
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: .7,
              child: Container(height: 4, color: accent),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: accent,
            ),
            ...lines,
          ],
        ),
      ),
    };

    return Container(
      width: 46,
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Always a white page, like the PDF, in light and dark themes.
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: body,
    );
  }
}
