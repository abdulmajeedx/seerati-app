import 'package:hive_flutter/hive_flutter.dart';

import '../../features/cover_letter/data/models/cover_letter.dart';
import '../../features/resume/data/models/resume.dart';
import '../constants/app_constants.dart';

abstract final class StorageService {
  /// [path] is only for tests; in the app Hive uses the app documents dir.
  static Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    Hive
      ..registerAdapter(ResumeAdapter())
      ..registerAdapter(PersonalInfoAdapter())
      ..registerAdapter(ExperienceItemAdapter())
      ..registerAdapter(EducationItemAdapter())
      ..registerAdapter(LanguageItemAdapter())
      ..registerAdapter(CourseItemAdapter())
      ..registerAdapter(CoverLetterAdapter());
    await Future.wait([
      Hive.openBox<dynamic>(AppConstants.settingsBox),
      Hive.openBox<Resume>(AppConstants.resumesBox),
      Hive.openBox<CoverLetter>(AppConstants.coverLettersBox),
    ]);
  }

  static Box<dynamic> get settings => Hive.box<dynamic>(AppConstants.settingsBox);
  static Box<Resume> get resumes => Hive.box<Resume>(AppConstants.resumesBox);
  static Box<CoverLetter> get coverLetters =>
      Hive.box<CoverLetter>(AppConstants.coverLettersBox);
}
