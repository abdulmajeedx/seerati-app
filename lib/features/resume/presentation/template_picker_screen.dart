import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.name,
    required this.spec,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final TemplateSpec spec;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = Color(spec.accent.toInt() | 0xFF000000);
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: spec.filledHeader
                              ? accent
                              : accent.withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 5; i++)
                        Container(
                          height: 5,
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      Container(width: 36, height: 3, color: accent),
                    ],
                  ),
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
