import 'package:flutter_test/flutter_test.dart';
import 'package:seerati/features/resume/data/models/resume.dart';
import 'package:seerati/features/resume/services/pdf_service.dart';

Resume _sample(String lang) => Resume(
      id: 'test-$lang',
      title: lang == 'ar' ? 'سيرة تجريبية' : 'Test Resume',
      language: lang,
      personalInfo: PersonalInfo(
        fullName: lang == 'ar' ? 'أحمد علي' : 'Ahmed Ali',
        jobTitle: lang == 'ar' ? 'مهندس برمجيات' : 'Software Engineer',
        phone: '+966500000000',
        email: 'ahmed@example.com',
        city: lang == 'ar' ? 'الرياض' : 'Riyadh',
      ),
      summary: lang == 'ar' ? 'ملخص مهني قصير.' : 'A short summary.',
      experiences: [
        ExperienceItem(
          jobTitle: lang == 'ar' ? 'مطور تطبيقات' : 'App Developer',
          company: lang == 'ar' ? 'شركة التقنية' : 'Tech Co',
          startDate: DateTime(2022, 3),
          isCurrent: true,
          description: lang == 'ar' ? 'تطوير تطبيقات Flutter.' : 'Flutter apps.',
        ),
      ],
      educations: [
        EducationItem(
          degree: lang == 'ar' ? 'بكالوريوس حاسب' : 'BSc Computer Science',
          institution: lang == 'ar' ? 'جامعة الملك سعود' : 'KSU',
          startDate: DateTime(2017, 9),
          endDate: DateTime(2021, 6),
        ),
      ],
      skills: ['Flutter', 'Dart'],
      languages: [LanguageItem(name: lang == 'ar' ? 'العربية' : 'Arabic', level: 'native')],
      courses: [CourseItem(name: 'Clean Code', issuer: 'Udemy', year: '2023')],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  for (final lang in ['ar', 'en']) {
    for (final template in ['classic', 'modern', 'minimal', 'colorful']) {
      testWidgets('builds $lang PDF with $template template', (tester) async {
        await tester.runAsync(() async {
          final resume = _sample(lang)..templateId = template;
          final withMark =
              await PdfService.build(resume, watermark: true);
          final noMark =
              await PdfService.build(resume, watermark: false);
          expect(withMark.length, greaterThan(1000));
          expect(noMark.length, greaterThan(1000));
          // %PDF magic header
          expect(String.fromCharCodes(withMark.take(4)), '%PDF');
        });
      });
    }
  }
}
