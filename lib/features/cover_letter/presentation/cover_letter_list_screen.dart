import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/cover_letter.dart';
import 'ai_cover_letter_screen.dart';
import 'cover_letter_editor_screen.dart';
import 'cover_letter_form_screen.dart';

class CoverLetterListScreen extends StatelessWidget {
  const CoverLetterListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, CoverLetter letter) async {
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
    if (ok == true) await StorageService.coverLetters.delete(letter.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myCoverLetters),
        actions: [
          if (ApiClient.isConfigured)
            IconButton(
              icon: const Icon(Icons.auto_awesome_outlined),
              tooltip: l10n.coverLetterFromAd,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiCoverLetterScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.newCoverLetter),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CoverLetterFormScreen()),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: StorageService.coverLetters.listenable(),
        builder: (context, Box<CoverLetter> box, _) {
          final letters = box.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          if (letters.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.noCoverLettersYet,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: letters.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final letter = letters[i];
              final title = letter.companyName.trim().isNotEmpty
                  ? letter.companyName
                  : (letter.jobTitle.trim().isNotEmpty
                      ? letter.jobTitle
                      : l10n.untitledLetter);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: Text(title),
                  subtitle: Text(
                      DateFormat.yMMMd(localeCode).format(letter.updatedAt)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            CoverLetterEditorScreen(letter: letter)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.delete,
                    onPressed: () => _confirmDelete(context, letter),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
