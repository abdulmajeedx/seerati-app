import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/app.dart';
import 'package:seerati/core/services/storage_service.dart';

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  testWidgets('app boots to welcome screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SeeratiApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Seerati'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
