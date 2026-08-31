import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/storage_service.dart';
import '../../../l10n/app_localizations.dart';
import '../data/models/resume.dart';
import 'steps/education_step.dart';
import 'steps/experience_step.dart';
import 'steps/extras_step.dart';
import 'steps/personal_info_step.dart';
import 'steps/skills_step.dart';
import 'steps/summary_step.dart';

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
    Navigator.of(context).pop(_draft);
  }

  StepState _stateFor(int index) {
    if (index == _step) return StepState.editing;
    return index < _step ? StepState.complete : StepState.indexed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l10n.newResume : l10n.edit),
      ),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (i) => setState(() => _step = i),
        onStepContinue: _next,
        onStepCancel: _back,
        controlsBuilder: (context, details) {
          if (details.stepIndex != _step) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsetsDirectional.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(
                      _step == _stepCount - 1 ? l10n.done : l10n.next,
                    ),
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.back),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n.personalInfo),
            state: _stateFor(0),
            content: PersonalInfoStep(draft: _draft, formKey: _personalFormKey),
          ),
          Step(
            title: Text(l10n.summary),
            state: _stateFor(1),
            content: SummaryStep(draft: _draft),
          ),
          Step(
            title: Text(l10n.experience),
            state: _stateFor(2),
            content: ExperienceStep(draft: _draft),
          ),
          Step(
            title: Text(l10n.education),
            state: _stateFor(3),
            content: EducationStep(draft: _draft),
          ),
          Step(
            title: Text(l10n.skills),
            state: _stateFor(4),
            content: SkillsStep(draft: _draft),
          ),
          Step(
            title: Text('${l10n.extrasStep} (${l10n.optionalHint})'),
            state: _stateFor(5),
            content: ExtrasStep(draft: _draft),
          ),
        ],
      ),
    );
  }
}
