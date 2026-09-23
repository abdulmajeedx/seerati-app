import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/discard_changes.dart';
import '../data/models/resume.dart';
import 'steps/education_step.dart';
import 'steps/experience_step.dart';
import 'steps/extras_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/skills_step.dart';
import 'steps/summary_step.dart';
import 'resume_preview_screen.dart';
import 'template_picker_screen.dart';

class ResumeFormScreen extends StatefulWidget {
  const ResumeFormScreen({super.key, this.existing});

  final Resume? existing;

  @override
  State<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends State<ResumeFormScreen> {
  late final Resume _draft;
  final _personalFormKey = GlobalKey<FormState>();
  int _step = 0;
  static const _stepCount = 6;

  /// The draft as it was when the screen opened, to detect unsaved edits.
  late final String _initial;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.existing?.copy() ??
        Resume(
          id: const Uuid().v4(),
          title: '',
          language: 'ar',
          personalInfo: PersonalInfo(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _initial = jsonEncode(_draft.toJson());
  }

  bool get _dirty => jsonEncode(_draft.toJson()) != _initial;

  /// Back steps through the form first, then asks before dropping edits.
  Future<void> _handleBack() async {
    if (_step > 0) {
      _back();
      return;
    }
    if (_dirty && !await confirmDiscardChanges(context)) return;
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_step == 0 && !(_personalFormKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!(_personalFormKey.currentState?.validate() ?? false)) {
      setState(() => _step = 0);
      return;
    }
    _draft.updatedAt = DateTime.now();
    if (_draft.title.trim().isEmpty) {
      _draft.title = _draft.personalInfo.fullName.trim().isEmpty
          ? l10n.untitledResume
          : _draft.personalInfo.fullName.trim();
    }
    await StorageService.resumes.put(_draft.id, _draft);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.resumeSaved)));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TemplatePickerScreen(resume: _draft)),
    );
  }

  /// Jumping forward past the first step still requires a valid name.
  void _goTo(int index) {
    if (index == _step) return;
    if (_step == 0 &&
        index > 0 &&
        !(_personalFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _step = index);
  }

  /// PDF of the draft as it stands, in its current template.
  void _preview() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResumePreviewScreen(resume: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <(String, Widget)>[
      (
        l10n.personalInfo,
        PersonalInfoStep(draft: _draft, formKey: _personalFormKey),
      ),
      (l10n.summary, SummaryStep(draft: _draft)),
      (l10n.experience, ExperienceStep(draft: _draft)),
      (l10n.education, EducationStep(draft: _draft)),
      (l10n.skills, SkillsStep(draft: _draft)),
      ('${l10n.extrasStep} (${l10n.optionalHint})', ExtrasStep(draft: _draft)),
    ];
    final isLast = _step == _stepCount - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? l10n.newResume : l10n.edit),
          actions: [
            IconButton(
              tooltip: l10n.preview,
              icon: const Icon(Icons.visibility_outlined),
              onPressed: _preview,
            ),
          ],
        ),
        body: Column(
          children: [
            _StepHeader(
              titles: [for (final (title, _) in steps) title],
              current: _step,
              onTap: _goTo,
            ),
            Expanded(
              // Every step stays mounted: they hold their own controllers,
              // and saving validates the first step's form from any step.
              child: IndexedStack(
                index: _step,
                children: [
                  for (final (_, content) in steps)
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: content,
                    ),
                ],
              ),
            ),
            // In the body, not bottomNavigationBar, so it rides above the
            // keyboard instead of hiding behind it.
            _StepControls(
              showBack: _step > 0,
              nextLabel: isLast ? l10n.done : l10n.next,
              nextIcon: isLast ? Icons.check : null,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Step 2 of 6 · Summary" over a row of tappable progress segments.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.titles,
    required this.current,
    required this.onTap,
  });

  final List<String> titles;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < titles.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == current,
                    label: titles[i],
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= current
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Text(
            l10n.stepOf(current + 1, titles.length),
            style: text.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              titles[current],
              key: ValueKey(current),
              style: text.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Back / Next pinned above the keyboard-safe bottom edge.
class _StepControls extends StatelessWidget {
  const _StepControls({
    required this.showBack,
    required this.nextLabel,
    required this.onBack,
    required this.onNext,
    this.nextIcon,
  });

  final bool showBack;
  final String nextLabel;
  final IconData? nextIcon;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (showBack) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(96, 52),
                  ),
                  onPressed: onBack,
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: nextIcon == null
                    ? FilledButton(onPressed: onNext, child: Text(nextLabel))
                    : FilledButton.icon(
                        onPressed: onNext,
                        icon: Icon(nextIcon),
                        label: Text(nextLabel),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
