import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/api_client.dart';
import '../../cover_letter/presentation/ai_cover_letter_screen.dart';
import '../../cover_letter/presentation/cover_letter_list_screen.dart';
import '../../resume/data/models/resume.dart';
import '../../resume/presentation/resume_form_screen.dart';
import '../../resume/presentation/resume_preview_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _deleteResume(BuildContext context, Resume resume) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    final photoPath = resume.personalInfo.photoPath;
    if (photoPath != null) {
      final file = File(photoPath);
      if (file.existsSync()) file.deleteSync();
    }
    await StorageService.resumes.delete(resume.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localeCode = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.theme,
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref
                .read(themeModeProvider.notifier)
                .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.language,
            icon: const Icon(Icons.translate),
            onSelected: (code) =>
                ref.read(localeProvider.notifier).setLocale(Locale(code)),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'ar', child: Text(l10n.arabic)),
              PopupMenuItem(value: 'en', child: Text(l10n.english)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            icon: Icons.article_outlined,
            title: l10n.newResume,
            subtitle: l10n.newResumeSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ResumeFormScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.mail_outline,
            title: l10n.coverLetter,
            subtitle: l10n.coverLetterSubtitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoverLetterListScreen()),
            ),
          ),
          if (ApiClient.isConfigured) ...[
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.auto_awesome_outlined,
              title: l10n.coverLetterFromAd,
              subtitle: l10n.coverLetterFromAdSubtitle,
              highlight: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiCoverLetterScreen()),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.myResumes,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: StorageService.resumes.listenable(),
            builder: (context, Box<Resume> box, _) {
              final resumes = box.values.toList()
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              if (resumes.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.noResumesYet,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final resume in resumes)
                    Card(
                      margin: const EdgeInsetsDirectional.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(resume.title),
                        subtitle: Text(
                          '${resume.personalInfo.jobTitle.trim().isNotEmpty ? '${resume.personalInfo.jobTitle} · ' : ''}'
                          '${DateFormat.yMMMd(localeCode).format(resume.updatedAt)}',
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  ResumeFormScreen(existing: resume)),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) {
                            switch (action) {
                              case 'edit':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ResumeFormScreen(
                                          existing: resume)),
                                );
                              case 'preview':
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => ResumePreviewScreen(
                                          resume: resume)),
                                );
                              case 'delete':
                                _deleteResume(context, resume);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'edit', child: Text(l10n.edit)),
                            PopupMenuItem(
                                value: 'preview', child: Text(l10n.preview)),
                            PopupMenuItem(
                                value: 'delete', child: Text(l10n.delete)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Card(
      color: highlight
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: highlight ? scheme.primary : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color:
                        highlight ? scheme.onPrimary : scheme.onPrimaryContainer,
                    size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: highlight
                                  ? scheme.onPrimaryContainer
                                  : scheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
