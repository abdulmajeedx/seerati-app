import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_delete.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/feature_card.dart';
import '../../../shared/widgets/layout.dart';
import '../../cover_letter/presentation/ai_cover_letter_screen.dart';
import '../../cover_letter/presentation/cover_letter_form_screen.dart';
import '../../cover_letter/presentation/cover_letter_list.dart';
import '../../jobs/presentation/job_search_screen.dart';
import '../../resume/data/models/resume.dart';
import '../../resume/data/resume_duplicator.dart';
import '../../resume/presentation/resume_form_screen.dart';
import '../../resume/presentation/resume_preview_screen.dart';
import '../../resume/presentation/template_picker_screen.dart';
import '../../resume/presentation/widgets/resume_card.dart';
import '../../update/presentation/update_banner.dart';
import 'settings_sheet.dart';

/// Two tabs — resumes and cover letters — with the create action for the
/// current tab as the floating button, and settings behind one icon.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  void _open(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aiReady = ApiClient.isConfigured;
    final jobsEnabled =
        aiReady &&
        (ref.watch(remoteConfigProvider).valueOrNull?.jobsEnabled ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? l10n.myResumes : l10n.myCoverLetters),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: FadeIndexedStack(
        index: _tab,
        children: [
          _ResumesTab(
            header: [
              if (jobsEnabled)
                FeatureCard(
                  icon: Icons.work_outline,
                  title: l10n.jobSearch,
                  subtitle: l10n.jobSearchSubtitle,
                  onTap: () => _open(const JobSearchScreen()),
                ),
            ],
          ),
          CoverLetterList(
            header: [
              if (aiReady)
                FeatureCard(
                  icon: Icons.auto_awesome_outlined,
                  title: l10n.coverLetterFromAd,
                  subtitle: l10n.coverLetterFromAdSubtitle,
                  onTap: () => _open(const AiCoverLetterScreen()),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        icon: const Icon(Icons.add),
        label: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _tab == 0 ? l10n.newResume : l10n.newCoverLetter,
              key: ValueKey(_tab),
            ),
          ),
        ),
        onPressed: () => _open(
          _tab == 0 ? const ResumeFormScreen() : const CoverLetterFormScreen(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.description_outlined),
            selectedIcon: const Icon(Icons.description),
            label: l10n.myResumes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.mail_outline),
            selectedIcon: const Icon(Icons.mail),
            label: l10n.myCoverLetters,
          ),
        ],
      ),
    );
  }
}

class _ResumesTab extends StatelessWidget {
  const _ResumesTab({required this.header});

  final List<Widget> header;

  Future<void> _delete(BuildContext context, Resume resume) async {
    if (!await confirmDelete(context)) return;
    final photoPath = resume.personalInfo.photoPath;
    if (photoPath != null) {
      final file = File(photoPath);
      if (file.existsSync()) file.deleteSync();
    }
    await StorageService.resumes.delete(resume.id);
  }

  Future<void> _duplicate(BuildContext context, Resume resume) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final copy = await duplicateResume(
      resume,
      title: l10n.copyOf(resume.title),
    );
    await StorageService.resumes.put(copy.id, copy);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.resumeDuplicated)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return ValueListenableBuilder(
      valueListenable: StorageService.resumes.listenable(),
      builder: (context, Box<Resume> box, _) {
        final resumes = box.values.toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return ListView(
          padding: readableHorizontalPadding(
            context,
          ).copyWith(top: 8, bottom: 96),
          children: [
            // Sizes to nothing when there's no update to offer.
            const UpdateBanner(),
            for (final w in header) ...[w, const SizedBox(height: 16)],
            if (resumes.isEmpty)
              EmptyState(
                icon: Icons.description_outlined,
                title: l10n.emptyResumesTitle,
                message: l10n.emptyResumesMsg,
                actionLabel: l10n.newResume,
                onAction: () => open(const ResumeFormScreen()),
              ),
            for (final resume in resumes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ResumeCard(
                  resume: resume,
                  onTap: () => open(ResumeFormScreen(existing: resume)),
                  onAction: (action) => switch (action) {
                    ResumeCardAction.edit => open(
                      ResumeFormScreen(existing: resume),
                    ),
                    ResumeCardAction.preview => open(
                      ResumePreviewScreen(resume: resume),
                    ),
                    ResumeCardAction.changeTemplate => open(
                      TemplatePickerScreen(resume: resume),
                    ),
                    ResumeCardAction.duplicate => _duplicate(context, resume),
                    ResumeCardAction.delete => _delete(context, resume),
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
