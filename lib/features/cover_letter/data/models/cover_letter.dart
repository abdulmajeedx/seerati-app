import 'package:hive/hive.dart';

part 'cover_letter.g.dart';

@HiveType(typeId: 6)
class CoverLetter extends HiveObject {
  CoverLetter({
    required this.id,
    required this.language,
    this.senderName = '',
    this.recipientName = '',
    this.companyName = '',
    this.jobTitle = '',
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
  });

  @HiveField(0)
  String id;

  /// 'ar' or 'en'.
  @HiveField(1)
  String language;

  @HiveField(2)
  String senderName;

  @HiveField(3)
  String recipientName;

  @HiveField(4)
  String companyName;

  @HiveField(5)
  String jobTitle;

  @HiveField(6)
  String body;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'language': language,
        'sender_name': senderName,
        'recipient_name': recipientName,
        'company_name': companyName,
        'job_title': jobTitle,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static CoverLetter fromJson(Map<String, dynamic> json) {
    String str(Object? v) => v is String ? v : '';
    DateTime date(Object? v) =>
        (v is String ? DateTime.tryParse(v) : null) ?? DateTime.now();
    return CoverLetter(
      id: str(json['id']),
      language: json['language'] == 'en' ? 'en' : 'ar',
      senderName: str(json['sender_name']),
      recipientName: str(json['recipient_name']),
      companyName: str(json['company_name']),
      jobTitle: str(json['job_title']),
      body: str(json['body']),
      createdAt: date(json['created_at']),
      updatedAt: date(json['updated_at']),
    );
  }

  CoverLetter copy() => CoverLetter(
        id: id,
        language: language,
        senderName: senderName,
        recipientName: recipientName,
        companyName: companyName,
        jobTitle: jobTitle,
        body: body,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
