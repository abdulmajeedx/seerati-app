import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/app.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/features/home/presentation/home_screen.dart';
import 'package:seerati/core/services/storage_service.dart';

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await tmp.delete(recursive: true);
  });

  testWidgets('returning user boots straight to home', (tester) async {
    await tester.runAsync(() =>
        StorageService.settings.put(AppConstants.onboardingDoneKey, true));
    await tester.pumpWidget(const ProviderScope(child: SeeratiApp()));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Welcome to Seerati'), findsNothing);
  });

  // Keep last: the app writes the flag from inside the fake-async zone, and
  // Hive's write queue never drains for later runAsync writes after that.
  testWidgets('first launch walks through onboarding to home',
      (tester) async {
    await tester.runAsync(() =>
        StorageService.settings.put(AppConstants.onboardingDoneKey, false));
    await tester.pumpWidget(const ProviderScope(child: SeeratiApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Seerati'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Templates that stand out'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your data stays with you'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    // The flag is written in the background; let the real disk write land.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    expect(StorageService.settings.get(AppConstants.onboardingDoneKey), true);
  });
}
