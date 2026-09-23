import 'dart:io';

import 'package:uuid/uuid.dart';

import 'models/resume.dart';

/// A deep copy of [source] under a new id and [title], ready to save. The
/// photo file is copied too: sharing one file would let deleting either
/// resume remove the other's photo.
Future<Resume> duplicateResume(Resume source, {required String title}) async {
  final id = const Uuid().v4();
  final now = DateTime.now();
  final copy = source.copy()
    ..id = id
    ..title = title
    ..createdAt = now
    ..updatedAt = now;

  final photoPath = source.personalInfo.photoPath;
  copy.personalInfo.photoPath = null;
  if (photoPath != null) {
    final photo = File(photoPath);
    if (photo.existsSync()) {
      final dot = photoPath.lastIndexOf('.');
      final ext = dot > photoPath.lastIndexOf('/')
          ? photoPath.substring(dot)
          : '';
      final target =
          '${photo.parent.path}/photo_${id}_${now.millisecondsSinceEpoch}$ext';
      copy.personalInfo.photoPath = (await photo.copy(target)).path;
    }
  }
  return copy;
}
