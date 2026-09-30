import 'package:flutter_test/flutter_test.dart';
import 'package:seerati/features/resume/data/models/resume.dart';
import 'package:seerati/features/resume/data/resume_completeness.dart';

Resume _resume({PersonalInfo? info}) => Resume(
  id: 'r',
  title: 't',
  language: 'en',
  personalInfo: info ?? PersonalInfo(),
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  test('an empty resume is 0% complete', () {
    expect(_resume().completeness, 0);
  });

  test('each expected part counts once; extras do not', () {
    final r =
        _resume(
            info: PersonalInfo(
              fullName: 'Ahmed',
              jobTitle: 'Dev',
              phone: '050',
            ),
          )
          ..languages = [LanguageItem(name: 'Arabic', level: 'native')]
          ..courses = [CourseItem(name: 'PMP')];
    // name, job title, contact
    expect(r.completedParts, 3);
  });

  test('email or phone satisfies contact; whitespace is not content', () {
    expect(_resume(info: PersonalInfo(email: 'a@b.c')).completedParts, 1);
    expect(_resume(info: PersonalInfo(fullName: '   ')).completedParts, 0);
  });

  test('a fully filled resume is 100%', () {
    final r =
        _resume(
            info: PersonalInfo(fullName: 'A', jobTitle: 'B', email: 'c@d.e'),
          )
          ..summary = 'S'
          ..experiences = [ExperienceItem(jobTitle: 'X')]
          ..educations = [EducationItem(degree: 'Y')]
          ..skills = ['Z'];
    expect(r.completeness, 1);
  });
}
