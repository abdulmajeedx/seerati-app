import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/services/storage_service.dart';
import '../../cover_letter/data/models/cover_letter.dart';
import '../../resume/data/models/resume.dart';

class BackupException implements Exception {
  const BackupException(this.reason);

  /// `invalidFile` covers unreadable, non-JSON and foreign files alike — the
  /// user can only act on one of them anyway.
  final BackupError reason;
}

enum BackupError { invalidFile, unsupportedVersion, empty }

class ImportResult {
  const ImportResult({
    required this.resumesAdded,
    required this.resumesUpdated,
    required this.lettersAdded,
    required this.lettersUpdated,
  });

  final int resumesAdded;
  final int resumesUpdated;
  final int lettersAdded;
  final int lettersUpdated;

  int get total => resumesAdded + resumesUpdated + lettersAdded + lettersUpdated;
}

/// Export/import of the user's own content as a single JSON file.
///
/// Deliberately excluded: the premium flag and anything device-scoped, so a
/// shared backup file can't hand out a paid unlock. Import never deletes —
/// entries merge by id, and the whole file is validated before a single write.
abstract final class BackupService {
  static const formatVersion = 1;
  static const _maxPhotoBytes = 3 * 1024 * 1024;

  static String fileName(DateTime now) =>
      'seerati-backup-${now.toIso8601String().substring(0, 10)}.json';

  static Future<String> export() async {
    final resumes = <Map<String, dynamic>>[];
    for (final resume in StorageService.resumes.values) {
      final json = resume.toJson();
      final path = resume.personalInfo.photoPath;
      if (path != null) {
        final file = File(path);
        if (file.existsSync() && file.lengthSync() <= _maxPhotoBytes) {
          json['photo_data'] = base64Encode(file.readAsBytesSync());
          json['photo_ext'] = path.contains('.') ? path.split('.').last : 'jpg';
        }
      }
      resumes.add(json);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'seerati-backup',
      'version': formatVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'resumes': resumes,
      'cover_letters': [
        for (final letter in StorageService.coverLetters.values) letter.toJson()
      ],
    });
  }

  /// Parses and validates without touching storage, so a bad file changes
  /// nothing.
  static ({List<Map<String, dynamic>> resumes, List<Map<String, dynamic>> letters})
      parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const BackupException(BackupError.invalidFile);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != 'seerati-backup') {
      throw const BackupException(BackupError.invalidFile);
    }
    final version = decoded['version'];
    if (version is! int || version > formatVersion) {
      throw const BackupException(BackupError.unsupportedVersion);
    }
    List<Map<String, dynamic>> entries(Object? value) => value is List
        ? value
            .whereType<Map<String, dynamic>>()
            .where((e) => (e['id'] as String?)?.isNotEmpty ?? false)
            .toList()
        : const [];

    final resumes = entries(decoded['resumes']);
    final letters = entries(decoded['cover_letters']);
    if (resumes.isEmpty && letters.isEmpty) {
      throw const BackupException(BackupError.empty);
    }
    return (resumes: resumes, letters: letters);
  }

  /// Merges a parsed backup into storage. Existing entries with the same id are
  /// overwritten; everything else is left alone.
  static Future<ImportResult> import(String raw, {String? photoDir}) async {
    final parsed = parse(raw);
    final resumeBox = StorageService.resumes;
    final letterBox = StorageService.coverLetters;
    var resumesAdded = 0, resumesUpdated = 0, lettersAdded = 0, lettersUpdated = 0;

    for (final json in parsed.resumes) {
      final resume = Resume.fromJson(json);
      final photo = json['photo_data'];
      if (photo is String && photo.isNotEmpty) {
        resume.personalInfo.photoPath =
            await _restorePhoto(resume.id, photo, json['photo_ext'], photoDir);
      }
      resumeBox.containsKey(resume.id) ? resumesUpdated++ : resumesAdded++;
      await resumeBox.put(resume.id, resume);
    }
    for (final json in parsed.letters) {
      final letter = CoverLetter.fromJson(json);
      letterBox.containsKey(letter.id) ? lettersUpdated++ : lettersAdded++;
      await letterBox.put(letter.id, letter);
    }
    return ImportResult(
      resumesAdded: resumesAdded,
      resumesUpdated: resumesUpdated,
      lettersAdded: lettersAdded,
      lettersUpdated: lettersUpdated,
    );
  }

  /// A corrupt photo must not fail the whole restore — the resume text matters
  /// more than the picture.
  static Future<String?> _restorePhoto(
      String resumeId, String data, Object? ext, String? photoDir) async {
    try {
      final bytes = base64Decode(data);
      if (bytes.length > _maxPhotoBytes) return null;
      final dir =
          photoDir ?? (await getApplicationDocumentsDirectory()).path;
      final extension = ext is String && ext.isNotEmpty ? ext : 'jpg';
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('$dir/photo_${resumeId}_$stamp.$extension');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}
