import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.mail_outline,
            title: l10n.coverLetter,
            subtitle: l10n.coverLetterSubtitle,
            onTap: () => _comingSoon(context),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.myResumes,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  l10n.noResumesYet,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Card(
      color: scheme.surfaceContainerHighest,
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
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 28),
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
                              color: scheme.onSurfaceVariant,
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
