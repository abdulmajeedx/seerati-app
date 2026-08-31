import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/core/services/storage_service.dart';
import 'package:seerati/features/backup/data/backup_service.dart';
import 'package:seerati/features/cover_letter/data/models/cover_letter.dart';
import 'package:seerati/features/resume/data/models/resume.dart';

Resume _resume(String id) => Resume(
      id: id,
      title: 'سيرتي',
      language: 'ar',
      templateId: 'modern',
      personalInfo: PersonalInfo(
        fullName: 'أحمد علي',
        jobTitle: 'مهندس برمجيات',
        phone: '+966500000000',
        email: 'a@example.com',
        city: 'الرياض',
      ),
      summary: 'ملخص مهني.',
      experiences: [
        ExperienceItem(
          jobTitle: 'مطور',
          company: 'شركة',
          startDate: DateTime(2022, 3),
          isCurrent: true,
          description: 'تطوير تطبيقات',
        ),
      ],
      educations: [
        EducationItem(
            degree: 'بكالوريوس',
            institution: 'جامعة',
            startDate: DateTime(2017, 9),
            endDate: DateTime(2021, 6)),
      ],
      skills: ['Flutter', 'Dart'],
      languages: [LanguageItem(name: 'العربية', level: 'native')],
      courses: [CourseItem(name: 'Clean Code', issuer: 'Udemy', year: '2023')],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 2, 2),
    );

CoverLetter _letter(String id) => CoverLetter(
      id: id,
      language: 'en',
      senderName: 'Ahmed',
      companyName: 'Tech Co',
      body: 'Dear Hiring Manager,',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_backup');
    await StorageService.init(path: tmp.path);
    await StorageService.resumes.clear();
    await StorageService.coverLetters.clear();
  });

  tearDown(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('a round trip preserves every field', () async {
    await StorageService.resumes.put('r1', _resume('r1'));
    await StorageService.coverLetters.put('c1', _letter('c1'));
    final json = await BackupService.export();

    await StorageService.resumes.clear();
    await StorageService.coverLetters.clear();
    final result = await BackupService.import(json, photoDir: tmp.path);

    expect(result.resumesAdded, 1);
    expect(result.lettersAdded, 1);
    final restored = StorageService.resumes.get('r1')!;
    expect(restored.title, 'سيرتي');
    expect(restored.templateId, 'modern');
    expect(restored.personalInfo.fullName, 'أحمد علي');
    expect(restored.personalInfo.email, 'a@example.com');
    expect(restored.summary, 'ملخص مهني.');
    expect(restored.skills, ['Flutter', 'Dart']);
    expect(restored.experiences.single.jobTitle, 'مطور');
    expect(restored.experiences.single.isCurrent, true);
    expect(restored.experiences.single.startDate, DateTime(2022, 3));
    expect(restored.experiences.single.endDate, isNull);
    expect(restored.educations.single.endDate, DateTime(2021, 6));
    expect(restored.languages.single.level, 'native');
    expect(restored.courses.single.issuer, 'Udemy');
    expect(restored.createdAt, DateTime(2026, 1, 1));
    expect(StorageService.coverLetters.get('c1')!.body, 'Dear Hiring Manager,');
  });

  test('a photo survives the round trip as a new file', () async {
    final photo = File('${tmp.path}/original.png')
      ..writeAsBytesSync(List<int>.filled(64, 7));
    final resume = _resume('r1')..personalInfo.photoPath = photo.path;
    await StorageService.resumes.put('r1', resume);

    final json = await BackupService.export();
    expect(jsonDecode(json)['resumes'][0]['photo_ext'], 'png');

    await StorageService.resumes.clear();
    photo.deleteSync();
    await BackupService.import(json, photoDir: tmp.path);

    final path = StorageService.resumes.get('r1')!.personalInfo.photoPath!;
    expect(File(path).existsSync(), true);
    expect(File(path).readAsBytesSync(), List<int>.filled(64, 7));
  });

  test('import merges by id and never deletes', () async {
    await StorageService.resumes.put('r1', _resume('r1'));
    final json = await BackupService.export();

    // A second resume the backup knows nothing about must survive.
    await StorageService.resumes.put('r2', _resume('r2')..title = 'أخرى');
    await StorageService.resumes.put('r1', _resume('r1')..title = 'محلي');

    final result = await BackupService.import(json, photoDir: tmp.path);
    expect(result.resumesUpdated, 1);
    expect(result.resumesAdded, 0);
    expect(StorageService.resumes.get('r1')!.title, 'سيرتي');
    expect(StorageService.resumes.get('r2')!.title, 'أخرى');
    expect(StorageService.resumes.length, 2);
  });

  test('a backup file cannot grant premium', () async {
    await StorageService.resumes.put('r1', _resume('r1'));
    final json = await BackupService.export();
    expect(json.contains(AppConstants.isPremiumKey), false);

    // Even a hand-edited file claiming premium changes nothing.
    final tampered = jsonDecode(json) as Map<String, dynamic>;
    tampered['is_premium'] = true;
    tampered['settings'] = {AppConstants.isPremiumKey: true};
    await BackupService.import(jsonEncode(tampered), photoDir: tmp.path);
    expect(
        StorageService.settings.get(AppConstants.isPremiumKey,
            defaultValue: false),
        false);
  });

  test('bad files are rejected before anything is written', () async {
    await StorageService.resumes.put('r1', _resume('r1'));

    Future<void> rejects(String raw, BackupError reason) async {
      await expectLater(
        BackupService.import(raw, photoDir: tmp.path),
        throwsA(isA<BackupException>()
            .having((e) => e.reason, 'reason', reason)),
      );
    }

    await rejects('not json at all', BackupError.invalidFile);
    await rejects('{"format":"something-else","version":1}',
        BackupError.invalidFile);
    await rejects(
        '{"format":"seerati-backup","version":99,"resumes":[]}',
        BackupError.unsupportedVersion);
    await rejects(
        '{"format":"seerati-backup","version":1,"resumes":[],'
        '"cover_letters":[]}',
        BackupError.empty);
    // Entries without an id are dropped, which leaves the file empty.
    await rejects(
        '{"format":"seerati-backup","version":1,"resumes":[{"title":"x"}]}',
        BackupError.empty);

    // Storage is untouched by every rejection above.
    expect(StorageService.resumes.length, 1);
    expect(StorageService.resumes.get('r1')!.title, 'سيرتي');
  });

  test('a corrupt photo does not fail the whole restore', () async {
    await StorageService.resumes.put('r1', _resume('r1'));
    final json = jsonDecode(await BackupService.export()) as Map<String, dynamic>;
    (json['resumes'] as List)[0]['photo_data'] = 'not-valid-base64!!';
    await StorageService.resumes.clear();

    final result = await BackupService.import(jsonEncode(json), photoDir: tmp.path);
    expect(result.resumesAdded, 1);
    expect(StorageService.resumes.get('r1')!.title, 'سيرتي');
    expect(StorageService.resumes.get('r1')!.personalInfo.photoPath, isNull);
  });
}
