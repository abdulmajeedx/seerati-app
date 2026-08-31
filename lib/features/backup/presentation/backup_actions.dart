import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/backup_service.dart';

/// Wires [BackupService] to the platform: a share sheet for export, a file
/// picker for import. All decisions and validation live in the service.
abstract final class BackupActions {
  static Future<void> export(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (StorageService.resumes.isEmpty &&
        StorageService.coverLetters.isEmpty) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.nothingToBackUp)));
      return;
    }
    try {
      final json = await BackupService.export();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${BackupService.fileName(DateTime.now())}');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          text: l10n.backupShareText,
        ),
      );
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }

  static Future<void> import(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    const type = XTypeGroup(label: 'Seerati backup', extensions: ['json']);
    final file = await openFile(acceptedTypeGroups: const [type]);
    if (file == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importConfirmTitle),
        content: Text(l10n.importConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.restore)),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await BackupService.import(await file.readAsString());
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.importDone(
            result.resumesAdded + result.lettersAdded,
            result.resumesUpdated + result.lettersUpdated,
          )),
        ));
    } on BackupException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(switch (e.reason) {
          BackupError.invalidFile => l10n.importInvalidFile,
          BackupError.unsupportedVersion => l10n.importUnsupportedVersion,
          BackupError.empty => l10n.importEmpty,
        })));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}
