import 'package:hive/hive.dart';

part 'resume.g.dart';

@HiveType(typeId: 0)
class Resume extends HiveObject {
  Resume({
    required this.id,
    required this.title,
    required this.language,
    this.templateId = 'classic',
    required this.personalInfo,
    this.summary = '',
    List<ExperienceItem>? experiences,
    List<EducationItem>? educations,
    List<String>? skills,
    List<LanguageItem>? languages,
    List<CourseItem>? courses,
    required this.createdAt,
    required this.updatedAt,
  })  : experiences = experiences ?? [],
        educations = educations ?? [],
        skills = skills ?? [],
        languages = languages ?? [],
        courses = courses ?? [];

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  /// 'ar' or 'en' — independent from the UI language.
  @HiveField(2)
  String language;

  @HiveField(3)
  String templateId;

  @HiveField(4)
  PersonalInfo personalInfo;

  @HiveField(5)
  String summary;

  @HiveField(6)
  List<ExperienceItem> experiences;

  @HiveField(7)
  List<EducationItem> educations;

  @HiveField(8)
  List<String> skills;

  @HiveField(9)
  List<LanguageItem> languages;

  @HiveField(10)
  List<CourseItem> courses;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  bool get isArabic => language == 'ar';
}

@HiveType(typeId: 1)
class PersonalInfo extends HiveObject {
  PersonalInfo({
    this.fullName = '',
    this.jobTitle = '',
    this.phone = '',
    this.email = '',
    this.city = '',
    this.photoPath,
  });

  @HiveField(0)
  String fullName;

  @HiveField(1)
  String jobTitle;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String email;

  @HiveField(4)
  String city;

  @HiveField(5)
  String? photoPath;
}

@HiveType(typeId: 2)
class ExperienceItem extends HiveObject {
  ExperienceItem({
    this.jobTitle = '',
    this.company = '',
    this.city = '',
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description = '',
  });

  @HiveField(0)
  String jobTitle;

  @HiveField(1)
  String company;

  @HiveField(2)
  String city;

  @HiveField(3)
  DateTime? startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  bool isCurrent;

  @HiveField(6)
  String description;
}

@HiveType(typeId: 3)
class EducationItem extends HiveObject {
  EducationItem({
    this.degree = '',
    this.institution = '',
    this.city = '',
    this.startDate,
    this.endDate,
    this.description = '',
  });

  @HiveField(0)
  String degree;

  @HiveField(1)
  String institution;

  @HiveField(2)
  String city;

  @HiveField(3)
  DateTime? startDate;

  @HiveField(4)
  DateTime? endDate;

  @HiveField(5)
  String description;
}

@HiveType(typeId: 4)
class LanguageItem extends HiveObject {
  LanguageItem({this.name = '', this.level = ''});

  @HiveField(0)
  String name;

  @HiveField(1)
  String level;
}

@HiveType(typeId: 5)
class CourseItem extends HiveObject {
  CourseItem({this.name = '', this.issuer = '', this.year = ''});

  @HiveField(0)
  String name;

  @HiveField(1)
  String issuer;

  @HiveField(2)
  String year;
}
