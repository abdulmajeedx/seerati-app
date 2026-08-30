// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resume.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResumeAdapter extends TypeAdapter<Resume> {
  @override
  final int typeId = 0;

  @override
  Resume read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Resume(
      id: fields[0] as String,
      title: fields[1] as String,
      language: fields[2] as String,
      templateId: fields[3] as String,
      personalInfo: fields[4] as PersonalInfo,
      summary: fields[5] as String,
      experiences: (fields[6] as List?)?.cast<ExperienceItem>(),
      educations: (fields[7] as List?)?.cast<EducationItem>(),
      skills: (fields[8] as List?)?.cast<String>(),
      languages: (fields[9] as List?)?.cast<LanguageItem>(),
      courses: (fields[10] as List?)?.cast<CourseItem>(),
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PersonalInfoAdapter extends TypeAdapter<PersonalInfo> {
  @override
  final int typeId = 1;

  @override
  PersonalInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonalInfo(
      fullName: fields[0] as String,
      jobTitle: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String,
      city: fields[4] as String,
      photoPath: fields[5] as String?,
    );
  }

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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExperienceItemAdapter extends TypeAdapter<ExperienceItem> {
  @override
  final int typeId = 2;

  @override
  ExperienceItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExperienceItem(
      jobTitle: fields[0] as String,
      company: fields[1] as String,
      city: fields[2] as String,
      startDate: fields[3] as DateTime?,
      endDate: fields[4] as DateTime?,
      isCurrent: fields[5] as bool,
      description: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExperienceItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.jobTitle)
      ..writeByte(1)
      ..write(obj.company)
      ..writeByte(2)
      ..write(obj.city)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.isCurrent)
      ..writeByte(6)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperienceItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EducationItemAdapter extends TypeAdapter<EducationItem> {
  @override
  final int typeId = 3;

  @override
  EducationItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EducationItem(
      degree: fields[0] as String,
      institution: fields[1] as String,
      city: fields[2] as String,
      startDate: fields[3] as DateTime?,
      endDate: fields[4] as DateTime?,
      description: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EducationItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.degree)
      ..writeByte(1)
      ..write(obj.institution)
      ..writeByte(2)
      ..write(obj.city)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EducationItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LanguageItemAdapter extends TypeAdapter<LanguageItem> {
  @override
  final int typeId = 4;

  @override
  LanguageItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LanguageItem(
      name: fields[0] as String,
      level: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LanguageItem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CourseItemAdapter extends TypeAdapter<CourseItem> {
  @override
  final int typeId = 5;

  @override
  CourseItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseItem(
      name: fields[0] as String,
      issuer: fields[1] as String,
      year: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CourseItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.issuer)
      ..writeByte(2)
      ..write(obj.year);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
