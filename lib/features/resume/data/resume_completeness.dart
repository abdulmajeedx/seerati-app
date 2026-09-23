import 'models/resume.dart';

/// How much of a resume is filled in, from the parts a reader expects:
/// name, job title, a way to reach you, summary, experience, education
/// and skills. Languages, courses and the photo are optional extras.
extension ResumeCompleteness on Resume {
  static const _parts = 7;

  int get completedParts {
    final info = personalInfo;
    bool filled(String v) => v.trim().isNotEmpty;
    return [
      filled(info.fullName),
      filled(info.jobTitle),
      filled(info.email) || filled(info.phone),
      filled(summary),
      experiences.isNotEmpty,
      educations.isNotEmpty,
      skills.isNotEmpty,
    ].where((done) => done).length;
  }

  /// 0.0 – 1.0
  double get completeness => completedParts / _parts;
}
