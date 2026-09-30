import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/services/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../backup/presentation/backup_actions.dart';

/// Appearance, language, backup and AI credits, in one bottom sheet instead
/// of a row of app-bar icons.
Future<void> showSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SettingsSheet(hostContext: context),
  );
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet({required this.hostContext});

  /// The screen under the sheet: backup actions outlive the sheet (share
  /// sheet, file picker, snackbars), so they run against it.
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final currentLang = Localizations.localeOf(context).languageCode;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(title, style: text.titleSmall),
    );

    void runOnHost(Future<void> Function(BuildContext) action) {
      Navigator.of(context).pop();
      action(hostContext);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.settings,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            section(l10n.theme),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(l10n.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(l10n.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(l10n.themeDark),
                ),
              ],
              selected: {themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setMode(s.first),
            ),
            section(l10n.language),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
                ButtonSegment(value: 'en', label: Text(l10n.english)),
              ],
              selected: {currentLang},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  ref.read(localeProvider.notifier).setLocale(Locale(s.first)),
            ),
            section(l10n.backup),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(l10n.exportBackup),
                    onTap: () => runOnHost(BackupActions.export),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.settings_backup_restore),
                    title: Text(l10n.importBackup),
                    onTap: () => runOnHost(BackupActions.import),
                  ),
                ],
              ),
            ),
            if (ApiClient.isConfigured)
              ValueListenableBuilder<int?>(
                valueListenable: ref.read(apiClientProvider).remainingCredits,
                builder: (context, credits, _) => credits == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ListTile(
                          leading: const Icon(Icons.bolt_outlined),
                          title: Text(l10n.creditsLeft(credits)),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
