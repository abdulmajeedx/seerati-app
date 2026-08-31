import 'package:flutter_test/flutter_test.dart';
import 'package:seerati/features/cover_letter/data/models/cover_letter.dart';
import 'package:seerati/features/cover_letter/services/cover_letter_generator.dart';
import 'package:seerati/features/cover_letter/services/cover_letter_pdf.dart';

CoverLetter _letter(String lang) => CoverLetter(
      id: 'cl-$lang',
      language: lang,
      senderName: lang == 'ar' ? 'أحمد علي' : 'Ahmed Ali',
      recipientName: lang == 'ar' ? 'سارة محمد' : 'Sara Mohammed',
      companyName: lang == 'ar' ? 'شركة التقنية' : 'Tech Co',
      jobTitle: lang == 'ar' ? 'مهندس برمجيات' : 'Software Engineer',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  test('generator fills Arabic template fields', () {
    final letter = _letter('ar');
    final body = CoverLetterGenerator.generate(letter);
    expect(body, contains('سارة محمد'));
    expect(body, contains('شركة التقنية'));
    expect(body, contains('مهندس برمجيات'));
    expect(body, contains('أحمد علي'));
  });

  test('generator fills English template fields', () {
    final letter = _letter('en');
    final body = CoverLetterGenerator.generate(letter);
    expect(body, contains('Sara Mohammed'));
    expect(body, contains('Tech Co'));
    expect(body, contains('Software Engineer'));
    expect(body, contains('Ahmed Ali'));
  });

  test('generator falls back when fields are empty', () {
    final ar = CoverLetter(
        id: 'x',
        language: 'ar',
        senderName: 'أحمد',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    expect(CoverLetterGenerator.generate(ar), contains('مدير التوظيف'));
    final en = CoverLetter(
        id: 'y',
        language: 'en',
        senderName: 'Ahmed',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026));
    expect(CoverLetterGenerator.generate(en), contains('Hiring Manager'));
  });

  for (final lang in ['ar', 'en']) {
    testWidgets('builds $lang cover letter PDF', (tester) async {
      await tester.runAsync(() async {
        final letter = _letter(lang)
          ..body = CoverLetterGenerator.generate(_letter(lang));
        final bytes = await CoverLetterPdf.build(letter, watermark: true);
        expect(bytes.length, greaterThan(1000));
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      });
    });
  }
}
