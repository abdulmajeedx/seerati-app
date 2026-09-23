import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_delete.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/layout.dart';
import '../data/models/cover_letter.dart';
import 'cover_letter_editor_screen.dart';
import 'cover_letter_form_screen.dart';

/// Saved cover letters, newest first. The home screen's second tab; its
/// [header] (e.g. the AI generator card) sits above the list.
class CoverLetterList extends StatelessWidget {
  const CoverLetterList({super.key, this.header = const []});

  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final localeCode = Localizations.localeOf(context).toString();
    return ValueListenableBuilder(
      valueListenable: StorageService.coverLetters.listenable(),
      builder: (context, Box<CoverLetter> box, _) {
        final letters = box.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ListView(
          padding: readableHorizontalPadding(
            context,
          ).copyWith(top: 8, bottom: 96),
          children: [
            for (final w in header) ...[w, const SizedBox(height: 16)],
            if (letters.isEmpty)
              EmptyState(
                icon: Icons.mail_outline,
                title: l10n.emptyLettersTitle,
                message: l10n.emptyLettersMsg,
                actionLabel: l10n.newCoverLetter,
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CoverLetterFormScreen(),
                  ),
                ),
              ),
            for (final letter in letters)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      6,
                      8,
                      6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                      child: const Icon(Icons.mail_outline),
                    ),
                    title: Text(
                      _title(letter, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (letter.companyName.trim().isNotEmpty &&
                            letter.jobTitle.trim().isNotEmpty)
                          letter.jobTitle,
                        DateFormat.yMMMd(localeCode).format(letter.updatedAt),
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CoverLetterEditorScreen(letter: letter),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.delete,
                      onPressed: () async {
                        if (await confirmDelete(context)) {
                          await StorageService.coverLetters.delete(letter.id);
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static String _title(CoverLetter letter, AppLocalizations l10n) =>
      letter.companyName.trim().isNotEmpty
      ? letter.companyName
      : (letter.jobTitle.trim().isNotEmpty
            ? letter.jobTitle
            : l10n.untitledLetter);
}
