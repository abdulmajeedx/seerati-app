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
}
