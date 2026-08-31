import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/cover_letter/data/models/cover_letter.dart';
import '../../features/resume/data/models/resume.dart';
import '../constants/app_constants.dart';

abstract final class StorageService {
  static const _encryptionKeyName = 'hive_encryption_key';
  // Presence of this file means the boxes are already encrypted. Opening a
  // box with the wrong cipher does NOT throw — Hive "recovers" by wiping it —
  // so the format must be known before opening anything.
  static const _markerFileName = 'seerati.encrypted';

  // Tests have no platform secure storage; they use a fixed key.
  static final List<int> _testKey = List<int>.generate(32, (i) => i + 1);

  /// [path] is only for tests; in the app Hive uses the app documents dir
  /// (same directory Hive.initFlutter used pre-1.1.0).
  static Future<void> init({String? path}) async {
    final String basePath;
    final List<int> key;
    if (path != null) {
      basePath = path;
      key = _testKey;
    } else {
      basePath = (await getApplicationDocumentsDirectory()).path;
      key = await _loadOrCreateKey();
    }
    Hive.init(basePath);
    if (!Hive.isAdapterRegistered(0)) {
      Hive
        ..registerAdapter(ResumeAdapter())
        ..registerAdapter(PersonalInfoAdapter())
        ..registerAdapter(ExperienceItemAdapter())
        ..registerAdapter(EducationItemAdapter())
        ..registerAdapter(LanguageItemAdapter())
        ..registerAdapter(CourseItemAdapter())
        ..registerAdapter(CoverLetterAdapter());
    }
    final cipher = HiveAesCipher(key);
    final marker = File('$basePath/$_markerFileName');
    final migrate = !marker.existsSync();
    await _open<dynamic>(AppConstants.settingsBox, cipher, migrate, basePath, null);
    await _open<Resume>(
        AppConstants.resumesBox, cipher, migrate, basePath, (r) => r.copy());
    await _open<CoverLetter>(AppConstants.coverLettersBox, cipher, migrate,
        basePath, (c) => c.copy());
    if (migrate) marker.writeAsStringSync('1');
  }

  static Future<List<int>> _loadOrCreateKey() async {
    const storage = FlutterSecureStorage();
    final stored = await storage.read(key: _encryptionKeyName);
    if (stored != null) return base64Decode(stored);
    final key = Hive.generateSecureKey();
    await storage.write(key: _encryptionKeyName, value: base64Encode(key));
    return key;
  }

  /// Migrates a pre-1.1.0 plain box to encrypted: backup file → plain read
  /// into memory → delete → recreate encrypted → restore.
  static Future<void> _open<T>(String name, HiveAesCipher cipher, bool migrate,
      String basePath, T Function(T)? detach) async {
    final boxFile = File('$basePath/$name.hive');
    if (!migrate || !boxFile.existsSync()) {
      await Hive.openBox<T>(name, encryptionCipher: cipher);
      return;
    }
    boxFile.copySync('${boxFile.path}.bak');
    final plain = await Hive.openBox<T>(name);
    final entries = plain
        .toMap()
        .map((k, v) => MapEntry(k, detach == null ? v : detach(v)));
    await plain.deleteFromDisk();
    final box = await Hive.openBox<T>(name, encryptionCipher: cipher);
    await box.putAll(entries);
  }

  static Box<dynamic> get settings => Hive.box<dynamic>(AppConstants.settingsBox);
  static Box<Resume> get resumes => Hive.box<Resume>(AppConstants.resumesBox);
  static Box<CoverLetter> get coverLetters =>
      Hive.box<CoverLetter>(AppConstants.coverLettersBox);
}
