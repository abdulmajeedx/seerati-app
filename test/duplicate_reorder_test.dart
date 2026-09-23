import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seerati/features/resume/data/models/resume.dart';
import 'package:seerati/features/resume/data/resume_duplicator.dart';
import 'package:seerati/shared/widgets/reorderable_entries.dart';

void main() {
  group('duplicateResume', () {
    late Directory tmp;
    setUp(() async => tmp = await Directory.systemTemp.createTemp('dup'));
    tearDown(() => tmp.delete(recursive: true));

    Resume source({String? photoPath}) => Resume(
          id: 'orig',
          title: 'Ahmed',
          language: 'en',
          templateId: 'modern',
          personalInfo: PersonalInfo(fullName: 'Ahmed', photoPath: photoPath),
          experiences: [ExperienceItem(jobTitle: 'Dev')],
          skills: ['Dart'],
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 2),
        );

    test('gets a new id and title and is a deep copy', () async {
      final original = source();
      final copy = await duplicateResume(original, title: 'Ahmed (copy)');
      expect(copy.id, isNot('orig'));
      expect(copy.title, 'Ahmed (copy)');
      expect(copy.templateId, 'modern');
      expect(copy.createdAt.isAfter(original.createdAt), isTrue);

      copy.experiences.first.jobTitle = 'Lead';
      copy.skills.add('Flutter');
      copy.personalInfo.fullName = 'Other';
      expect(original.experiences.first.jobTitle, 'Dev');
      expect(original.skills, ['Dart']);
      expect(original.personalInfo.fullName, 'Ahmed');
      expect(copy.personalInfo.photoPath, isNull);
    });

    test('the photo is copied to its own file', () async {
      final photo = File('${tmp.path}/photo_orig_1.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final copy =
          await duplicateResume(source(photoPath: photo.path), title: 'c');
      final copied = copy.personalInfo.photoPath!;
      expect(copied, isNot(photo.path));
      expect(copied, endsWith('.jpg'));
      expect(File(copied).readAsBytesSync(), [1, 2, 3]);

      // Deleting one resume's photo leaves the other's.
      photo.deleteSync();
      expect(File(copied).existsSync(), isTrue);
    });

    test('a missing photo file is dropped, not shared', () async {
      final copy = await duplicateResume(
          source(photoPath: '${tmp.path}/gone.jpg'),
          title: 'c');
      expect(copy.personalInfo.photoPath, isNull);
    });
  });

  testWidgets('entries reorder by dragging the handle', (tester) async {
    final items = ['A', 'B', 'C'];
    var changes = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ReorderableEntries<String>(
            items: items,
            onChanged: () => setState(() => changes++),
            itemBuilder: (context, item, i, handle) => SizedBox(
              height: 56,
              child: Row(children: [Expanded(child: Text(item)), ?handle]),
            ),
          ),
        ),
      ),
    ));

    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(3));
    final handle = find.byIcon(Icons.drag_indicator).first;
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 50));
    // Past the last entry's centre (entries are 56 tall).
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(items, ['B', 'C', 'A']);
    expect(changes, 1);
  });

  testWidgets('a single entry has no drag handle', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ReorderableEntries<String>(
          items: ['only'],
          onChanged: () {},
          itemBuilder: (context, item, i, handle) =>
              Row(children: [Text(item), ?handle]),
        ),
      ),
    ));
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
  });
}
