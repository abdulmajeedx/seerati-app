import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/hive_impl.dart';
import 'package:seerati/features/resume/data/models/resume.dart';

/// Writes records exactly as 2.5.0 did: Resume with fields 0–12 and
/// PersonalInfo with fields 0–5 (no projects, certifications, links, birth
/// date or nationality).
class _LegacyResumeAdapter extends TypeAdapter<Resume> {
  @override
  final int typeId = 0;

  @override
  Resume read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, Resume obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.language)
      ..writeByte(3)
      ..write(obj.templateId)
      ..writeByte(4)
      ..write(obj.personalInfo)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.experiences)
      ..writeByte(7)
      ..write(obj.educations)
      ..writeByte(8)
      ..write(obj.skills)
      ..writeByte(9)
      ..write(obj.languages)
      ..writeByte(10)
      ..write(obj.courses)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }
}

class _LegacyPersonalInfoAdapter extends TypeAdapter<PersonalInfo> {
  @override
  final int typeId = 1;

  @override
  PersonalInfo read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, PersonalInfo obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.jobTitle)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.city)
      ..writeByte(5)
      ..write(obj.photoPath);
  }
}

void main() {
  test('resumes saved by 2.5.0 open with the new fields defaulted', () async {
    final tmp = await Directory.systemTemp.createTemp('seerati_schema');
    addTearDown(() => tmp.delete(recursive: true));

    final old = HiveImpl()
      ..init(tmp.path)
      ..registerAdapter(_LegacyResumeAdapter())
      ..registerAdapter(_LegacyPersonalInfoAdapter());
    final oldBox = await old.openBox<Resume>('resumes');
    await oldBox.put(
      'r1',
      Resume(
        id: 'r1',
        title: 'Old',
        language: 'ar',
        personalInfo: PersonalInfo(fullName: 'أحمد', email: 'a@b.c'),
        skills: ['Dart'],
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      ),
    );
    await old.close();

    final current = HiveImpl()
      ..init(tmp.path)
      ..registerAdapter(ResumeAdapter())
      ..registerAdapter(PersonalInfoAdapter())
      ..registerAdapter(ExperienceItemAdapter())
      ..registerAdapter(EducationItemAdapter())
      ..registerAdapter(LanguageItemAdapter())
      ..registerAdapter(CourseItemAdapter())
      ..registerAdapter(ProjectItemAdapter());
    final box = await current.openBox<Resume>('resumes');
    final r = box.get('r1')!;
    expect(r.personalInfo.fullName, 'أحمد');
    expect(r.personalInfo.email, 'a@b.c');
    expect(r.skills, ['Dart']);
    expect(r.personalInfo.linkedin, '');
    expect(r.personalInfo.website, '');
    expect(r.personalInfo.nationality, '');
    expect(r.personalInfo.birthDate, isNull);
    expect(r.projects, isEmpty);
    expect(r.certifications, isEmpty);

    // And the new fields round-trip once written by the current adapters.
    r.personalInfo.linkedin = 'linkedin.com/in/ahmed';
    r.projects.add(ProjectItem(name: 'Seerati', link: 'github.com/x'));
    r.certifications.add(CourseItem(name: 'PMP', issuer: 'PMI'));
    await box.put('r1', r);
    await current.close();

    final reopened = HiveImpl()
      ..init(tmp.path)
      ..registerAdapter(ResumeAdapter())
      ..registerAdapter(PersonalInfoAdapter())
      ..registerAdapter(ExperienceItemAdapter())
      ..registerAdapter(EducationItemAdapter())
      ..registerAdapter(LanguageItemAdapter())
      ..registerAdapter(CourseItemAdapter())
      ..registerAdapter(ProjectItemAdapter());
    final again = (await reopened.openBox<Resume>('resumes')).get('r1')!;
    expect(again.personalInfo.linkedin, 'linkedin.com/in/ahmed');
    expect(again.projects.single.link, 'github.com/x');
    expect(again.certifications.single.issuer, 'PMI');
    await reopened.close();
  });
}
