import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/core/services/storage_service.dart';
import 'package:seerati/features/cover_letter/data/models/cover_letter.dart';
import 'package:seerati/features/resume/data/models/resume.dart';

void main() {
  test('pre-1.1.0 unencrypted boxes migrate with data intact', () async {
    final tmp = await Directory.systemTemp.createTemp('seerati_migration');
    addTearDown(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    // Simulate a v1.0.0 install: plain (unencrypted) boxes with data.
    Hive
      ..init(tmp.path)
      ..registerAdapter(ResumeAdapter())
      ..registerAdapter(PersonalInfoAdapter())
      ..registerAdapter(ExperienceItemAdapter())
      ..registerAdapter(EducationItemAdapter())
      ..registerAdapter(LanguageItemAdapter())
      ..registerAdapter(CourseItemAdapter())
      ..registerAdapter(CoverLetterAdapter());
    final settings = await Hive.openBox<dynamic>(AppConstants.settingsBox);
    await settings.put(AppConstants.isPremiumKey, true);
    final resumes = await Hive.openBox<Resume>(AppConstants.resumesBox);
    await resumes.put(
      'r1',
      Resume(
        id: 'r1',
        title: 'سيرتي القديمة',
        language: 'ar',
        personalInfo: PersonalInfo(fullName: 'أحمد علي'),
        skills: ['Flutter'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      ),
    );
    await Hive.close();

    // New version boots: init must migrate everything to encrypted boxes.
    await StorageService.init(path: tmp.path);

    expect(StorageService.settings.get(AppConstants.isPremiumKey), true);
    final migrated = StorageService.resumes.get('r1');
    expect(migrated, isNotNull);
    expect(migrated!.title, 'سيرتي القديمة');
    expect(migrated.personalInfo.fullName, 'أحمد علي');
    expect(migrated.skills, ['Flutter']);
    expect(StorageService.coverLetters.length, 0);
    expect(File('${tmp.path}/seerati.encrypted').existsSync(), true);
    expect(File('${tmp.path}/resumes.hive.bak').existsSync(), true);

    // Reopening with the cipher (fresh init) still works.
    await Hive.close();
    await StorageService.init(path: tmp.path);
    expect(StorageService.resumes.get('r1')!.title, 'سيرتي القديمة');
  });
}
