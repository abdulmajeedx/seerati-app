import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/api_error_message.dart';
import '../../resume/data/models/resume.dart';

class JobSearchScreen extends ConsumerStatefulWidget {
  const JobSearchScreen({super.key});

  @override
  ConsumerState<JobSearchScreen> createState() => _JobSearchScreenState();
}

class _JobSearchScreenState extends ConsumerState<JobSearchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _role = TextEditingController();
  final _city = TextEditingController();
  bool _remote = true;
  bool _busy = false;
  List<JobResult>? _results;

  @override
  void initState() {
    super.initState();
    // Prefill from the most recently edited resume.
    final resume = _latestResume();
    if (resume != null) {
      _role.text = resume.personalInfo.jobTitle;
      _city.text = resume.personalInfo.city;
    }
  }

  @override
  void dispose() {
    _role.dispose();
    _city.dispose();
    super.dispose();
  }

  Resume? _latestResume() {
    final resumes = StorageService.resumes.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return resumes.isEmpty ? null : resumes.first;
  }

  Future<void> _search() async {
    if (!_formKey.currentState!.validate()) return;
    final resume = _latestResume();
    setState(() => _busy = true);
    try {
      final results = await ref.read(apiClientProvider).searchJobs(
            language: Localizations.localeOf(context).languageCode == 'en'
                ? 'en'
                : 'ar',
            jobTitle: _role.text.trim(),
            city: _city.text.trim(),
            remote: _remote,
            skills: resume?.skills ?? const [],
            resumeSummary: resume?.summary ?? '',
          );
      if (!mounted) return;
      setState(() => _results = results);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(String url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.jobSearch)),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  TextFormField(
                    controller: _role,
                    decoration: InputDecoration(labelText: l10n.desiredRole),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.requiredField
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _city,
                    decoration: InputDecoration(labelText: l10n.city),
                  ),
                  SwitchListTile(
                    value: _remote,
                    title: Text(l10n.remoteOk),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _remote = v),
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _search,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_busy ? l10n.aiWorking : l10n.searchJobs),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (results) {
              null => const SizedBox.shrink(),
              [] => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l10n.noJobsFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ),
              _ => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _JobCard(job: results[i], onOpen: () => _open(results[i].url)),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.onOpen});

  final JobResult job;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                [job.company, job.location]
                    .where((s) => s.isNotEmpty)
                    .join(' · '),
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (job.whyMatch.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_outlined,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(job.whyMatch,
                          style: Theme.of(context).textTheme.bodySmall),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l10n.openJobPost),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
