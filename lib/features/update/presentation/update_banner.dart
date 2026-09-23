import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/update_checker.dart';

/// "Version x is available" card, shown until the user downloads or
/// dismisses that version (a newer one shows again).
class UpdateBanner extends ConsumerStatefulWidget {
  const UpdateBanner({super.key});

  @override
  ConsumerState<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends ConsumerState<UpdateBanner> {
  String? _dismissed =
      StorageService.settings.get(AppConstants.dismissedUpdateKey) as String?;

  void _dismiss(String version) {
    setState(() => _dismissed = version);
    unawaited(
      StorageService.settings.put(AppConstants.dismissedUpdateKey, version),
    );
  }

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(updateProvider).valueOrNull;
    if (update == null || update.version == _dismissed) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.tertiaryContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update_outlined,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.updateAvailableTitle(update.version),
                    style: text.titleMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.updateAvailableMsg,
              style: text.bodySmall?.copyWith(
                color: scheme.onTertiaryContainer,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _dismiss(update.version),
                  child: Text(l10n.updateLater),
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(l10n.updateDownload),
                  onPressed: () => launchUrl(
                    update.downloadUrl,
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
