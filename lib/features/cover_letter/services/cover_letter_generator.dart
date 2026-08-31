import '../data/models/cover_letter.dart';

abstract final class CoverLetterGenerator {
  static String generate(CoverLetter letter) =>
      letter.language == 'ar' ? _arabic(letter) : _english(letter);

  static String _arabic(CoverLetter l) {
    final recipient =
        l.recipientName.trim().isEmpty ? 'مدير التوظيف' : l.recipientName.trim();
    final company =
        l.companyName.trim().isEmpty ? 'شركتكم الموقرة' : l.companyName.trim();
    final position = l.jobTitle.trim().isEmpty
        ? 'الوظيفة المعلن عنها'
        : 'وظيفة ${l.jobTitle.trim()}';
    final sender = l.senderName.trim();
    return '''
السيد/ة $recipient المحترم/ة،

تحية طيبة وبعد،

أتقدم إليكم برغبتي في الالتحاق بـ$position لدى $company. أمتلك من المهارات والخبرات ما يؤهلني للمساهمة بفاعلية في فريق عملكم، وأحرص دائمًا على التطوير المستمر وتحقيق الأهداف بجودة عالية.

سأكون ممتنًا لإتاحة الفرصة لمقابلة شخصية أستعرض فيها خبراتي وكيف يمكنني إضافة قيمة لمؤسستكم.

شاكرًا لكم حسن اهتمامكم، وتفضلوا بقبول فائق الاحترام والتقدير.

$sender''';
  }

  static String _english(CoverLetter l) {
    final recipient = l.recipientName.trim().isEmpty
        ? 'Hiring Manager'
        : l.recipientName.trim();
    final company =
        l.companyName.trim().isEmpty ? 'your company' : l.companyName.trim();
    final position = l.jobTitle.trim().isEmpty
        ? 'the advertised position'
        : 'the ${l.jobTitle.trim()} position';
    final sender = l.senderName.trim();
    return '''
Dear $recipient,

I am writing to express my interest in $position at $company. With my skills and experience, I am confident I can contribute effectively to your team, and I am committed to continuous growth and delivering high-quality results.

I would welcome the opportunity to discuss in person how my background can add value to your organization.

Thank you for your time and consideration.

Sincerely,
$sender''';
  }
}
