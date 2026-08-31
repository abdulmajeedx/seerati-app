/// Strings rendered INSIDE the PDF. They follow the resume's language,
/// not the UI locale, so they intentionally live outside the ARB files.
class ResumeStrings {
  const ResumeStrings._({
    required this.summary,
    required this.experience,
    required this.education,
    required this.skills,
    required this.languages,
    required this.courses,
    required this.present,
    required this.months,
    required this.levels,
  });

  final String summary;
  final String experience;
  final String education;
  final String skills;
  final String languages;
  final String courses;
  final String present;
  final List<String> months;
  final Map<String, String> levels;

  static ResumeStrings of(String language) => language == 'ar' ? _ar : _en;

  String formatDate(DateTime d) => '${months[d.month - 1]} ${d.year}';

  String levelLabel(String key) => levels[key] ?? key;

  static const _en = ResumeStrings._(
    summary: 'Summary',
    experience: 'Experience',
    education: 'Education',
    skills: 'Skills',
    languages: 'Languages',
    courses: 'Courses',
    present: 'Present',
    months: [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ],
    levels: {
      'beginner': 'Beginner',
      'intermediate': 'Intermediate',
      'advanced': 'Advanced',
      'native': 'Native',
    },
  );

  static const _ar = ResumeStrings._(
    summary: 'الملخص',
    experience: 'الخبرات',
    education: 'التعليم',
    skills: 'المهارات',
    languages: 'اللغات',
    courses: 'الدورات',
    present: 'حتى الآن',
    months: [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ],
    levels: {
      'beginner': 'مبتدئ',
      'intermediate': 'متوسط',
      'advanced': 'متقدم',
      'native': 'اللغة الأم',
    },
  );
}
