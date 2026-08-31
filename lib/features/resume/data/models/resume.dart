import 'package:hive/hive.dart';

part 'resume.g.dart';

String _str(Object? value, {String fallback = ''}) =>
    value is String ? value : fallback;

DateTime _date(Object? value) =>
    (value is String ? DateTime.tryParse(value) : null) ?? DateTime.now();

DateTime? _nullableDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic> _map(Object? value) =>
    value is Map<String, dynamic> ? value : const {};

List<Map<String, dynamic>> _list(Object? value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const [];

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

  /// Backup format. Photos travel separately (as base64) because they live on
  /// disk, not in the box.
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'language': language,
        'template_id': templateId,
        'personal_info': personalInfo.toJson(),
        'summary': summary,
        'experiences': [for (final e in experiences) e.toJson()],
        'educations': [for (final e in educations) e.toJson()],
        'skills': skills,
        'languages': [for (final e in languages) e.toJson()],
        'courses': [for (final e in courses) e.toJson()],
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static Resume fromJson(Map<String, dynamic> json) => Resume(
        id: _str(json['id']),
        title: _str(json['title']),
        language: json['language'] == 'en' ? 'en' : 'ar',
        templateId: _str(json['template_id'], fallback: 'classic'),
        personalInfo: PersonalInfo.fromJson(_map(json['personal_info'])),
        summary: _str(json['summary']),
        experiences: [
          for (final e in _list(json['experiences']))
            ExperienceItem.fromJson(e)
        ],
        educations: [
          for (final e in _list(json['educations'])) EducationItem.fromJson(e)
        ],
        skills: [
          for (final s in (json['skills'] as List? ?? const []))
            if (s is String) s
        ],
        languages: [
          for (final e in _list(json['languages'])) LanguageItem.fromJson(e)
        ],
        courses: [
          for (final e in _list(json['courses'])) CourseItem.fromJson(e)
        ],
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
      );

  Resume copy() => Resume(
        id: id,
        title: title,
        language: language,
        templateId: templateId,
        personalInfo: personalInfo.copy(),
        summary: summary,
        experiences: [for (final e in experiences) e.copy()],
        educations: [for (final e in educations) e.copy()],
        skills: List.of(skills),
        languages: [for (final e in languages) e.copy()],
        courses: [for (final e in courses) e.copy()],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
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

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'job_title': jobTitle,
        'phone': phone,
        'email': email,
        'city': city,
      };

  static PersonalInfo fromJson(Map<String, dynamic> json) => PersonalInfo(
        fullName: _str(json['full_name']),
        jobTitle: _str(json['job_title']),
        phone: _str(json['phone']),
        email: _str(json['email']),
        city: _str(json['city']),
      );

  PersonalInfo copy() => PersonalInfo(
        fullName: fullName,
        jobTitle: jobTitle,
        phone: phone,
        email: email,
        city: city,
        photoPath: photoPath,
      );
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

  Map<String, dynamic> toJson() => {
        'job_title': jobTitle,
        'company': company,
        'city': city,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_current': isCurrent,
        'description': description,
      };

  static ExperienceItem fromJson(Map<String, dynamic> json) => ExperienceItem(
        jobTitle: _str(json['job_title']),
        company: _str(json['company']),
        city: _str(json['city']),
        startDate: _nullableDate(json['start_date']),
        endDate: _nullableDate(json['end_date']),
        isCurrent: json['is_current'] == true,
        description: _str(json['description']),
      );

  ExperienceItem copy() => ExperienceItem(
        jobTitle: jobTitle,
        company: company,
        city: city,
        startDate: startDate,
        endDate: endDate,
        isCurrent: isCurrent,
        description: description,
      );
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

  Map<String, dynamic> toJson() => {
        'degree': degree,
        'institution': institution,
        'city': city,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'description': description,
      };

  static EducationItem fromJson(Map<String, dynamic> json) => EducationItem(
        degree: _str(json['degree']),
        institution: _str(json['institution']),
        city: _str(json['city']),
        startDate: _nullableDate(json['start_date']),
        endDate: _nullableDate(json['end_date']),
        description: _str(json['description']),
      );

  EducationItem copy() => EducationItem(
        degree: degree,
        institution: institution,
        city: city,
        startDate: startDate,
        endDate: endDate,
        description: description,
      );
}

@HiveType(typeId: 4)
class LanguageItem extends HiveObject {
  LanguageItem({this.name = '', this.level = ''});

  @HiveField(0)
  String name;

  @HiveField(1)
  String level;

  Map<String, dynamic> toJson() => {'name': name, 'level': level};

  static LanguageItem fromJson(Map<String, dynamic> json) =>
      LanguageItem(name: _str(json['name']), level: _str(json['level']));

  LanguageItem copy() => LanguageItem(name: name, level: level);
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

  Map<String, dynamic> toJson() =>
      {'name': name, 'issuer': issuer, 'year': year};

  static CourseItem fromJson(Map<String, dynamic> json) => CourseItem(
        name: _str(json['name']),
        issuer: _str(json['issuer']),
        year: _str(json['year']),
      );

  CourseItem copy() => CourseItem(name: name, issuer: issuer, year: year);
}
