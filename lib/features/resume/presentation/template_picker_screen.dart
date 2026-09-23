import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/premium_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../paywall/presentation/paywall_screen.dart';
import '../data/models/resume.dart';
import '../templates/templates.dart';
import 'resume_preview_screen.dart';

class TemplatePickerScreen extends ConsumerWidget {
  const TemplatePickerScreen({super.key, required this.resume});

  final Resume resume;

  String _name(String id, AppLocalizations l10n) => switch (id) {
        AppConstants.templateClassic => l10n.templateClassic,
        AppConstants.templateModern => l10n.templateModern,
        AppConstants.templateMinimal => l10n.templateMinimal,
        AppConstants.templateColorful => l10n.templateColorful,
        _ => id,
      };

  Future<void> _select(
      BuildContext context, WidgetRef ref, TemplateSpec spec) async {
    final premium = ref.read(premiumProvider);
    if (!spec.free && !premium) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }
    resume.templateId = spec.id;
    await StorageService.resumes.put(resume.id, resume);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResumePreviewScreen(resume: resume)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final premium = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chooseTemplate)),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .72,
        children: [
          for (final spec in TemplateSpec.specs)
            _TemplateCard(
              resume: resume,
              name: _name(spec.id, l10n),
              spec: spec,
              locked: !spec.free && !premium,
              selected: resume.templateId == spec.id,
              onTap: () => _select(context, ref, spec),
            ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.resume,
    required this.name,
    required this.spec,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final Resume resume;
  final String name;
  final TemplateSpec spec;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _TemplateThumbnail(resume: resume, spec: spec),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (locked)
                    Icon(Icons.lock_outline,
                        size: 18, color: scheme.onSurfaceVariant)
                  else if (spec.free)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(l10n.free,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onPrimaryContainer)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// First page of the user's own resume rendered in [spec]. The schematic
/// sketch stands in while it renders, or if rasterizing isn't available.
class _TemplateThumbnail extends StatefulWidget {
  const _TemplateThumbnail({required this.resume, required this.spec});

  final Resume resume;
  final TemplateSpec spec;

  @override
  State<_TemplateThumbnail> createState() => _TemplateThumbnailState();
}

class _TemplateThumbnailState extends State<_TemplateThumbnail> {
  late final Future<PdfRaster> _page = _render();

  Future<PdfRaster> _render() async {
    final bytes =
        await buildResumePdf(widget.resume, widget.spec, watermark: false);
    // ~500px wide for an A4 page: sharp on a half-width card at 3x.
    return Printing.raster(bytes, pages: const [0], dpi: 60).first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PdfRaster>(
      future: _page,
      builder: (context, snapshot) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: snapshot.hasData
            ? Image(
                key: const ValueKey('page'),
                image: PdfRasterImage(snapshot.data!),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.medium,
              )
            : _TemplateSketch(spec: widget.spec),
      ),
    );
  }
}

class _TemplateSketch extends StatelessWidget {
  const _TemplateSketch({required this.spec});

  final TemplateSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = Color(spec.accent.toInt() | 0xFF000000);
    Widget bar(double height, Color color, {double? width}) => Container(
          height: height,
          width: width ?? double.infinity,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    final lines = [
      for (var i = 0; i < 5; i++) bar(5, scheme.outlineVariant),
    ];
    final body = switch (spec.layout) {
      TemplateLayout.sidebar => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 30,
              color: accent.withValues(alpha: .15),
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                CircleAvatar(radius: 10, backgroundColor: accent),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(children: [
                  bar(8, accent, width: 50),
                  const SizedBox(height: 4),
                  ...lines,
                ]),
              ),
            ),
          ],
        ),
      TemplateLayout.minimal => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(9, scheme.onSurfaceVariant, width: 60),
              bar(1, scheme.outline),
              const SizedBox(height: 4),
              for (var i = 0; i < 4; i++)
                Row(children: [
                  SizedBox(width: 20, child: i.isEven ? bar(4, accent) : null),
                  const SizedBox(width: 6),
                  Expanded(child: bar(5, scheme.outlineVariant)),
                ]),
            ],
          ),
        ),
      TemplateLayout.banner => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 28, color: accent),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(children: lines),
            ),
          ],
        ),
      TemplateLayout.classic => Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(8, accent, width: 60),
              bar(1.5, accent),
              const SizedBox(height: 4),
              ...lines,
            ],
          ),
        ),
    };
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: scheme.surfaceContainerHighest,
      child: body,
    );
  }
}
