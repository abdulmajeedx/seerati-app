import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/core/services/storage_service.dart';
import 'package:seerati/features/resume/presentation/resume_form_screen.dart';
import 'package:seerati/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
      child: _app(child, locale));
}

Widget _app(Widget child, Locale locale) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_form_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    try {
      // A write initiated inside a test's FakeAsync zone can strand Hive's
      // internal lock, making close() hang forever.
      await Hive.close().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // ignore: box files are removed below anyway
    }
    await tmp.delete(recursive: true);
  });

  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('empty name blocks step 1', (tester) async {
    enlargeSurface(tester);
    await tester.pumpWidget(_wrap(const ResumeFormScreen()));
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('completing the stepper saves a resume to Hive', (tester) async {
    enlargeSurface(tester);
    await tester.runAsync(() => StorageService.resumes.clear());
    await tester.pumpWidget(_wrap(const ResumeFormScreen()));

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 'Ahmed Ali');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pump();
    // Hive writes use real file IO which never completes inside the
    // FakeAsync test zone; runAsync drives the real event loop.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(seconds: 1));

    expect(StorageService.resumes.length, 1);
    final saved = StorageService.resumes.values.first;
    expect(saved.personalInfo.fullName, 'Ahmed Ali');
    expect(saved.title, 'Ahmed Ali');
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('form renders RTL in Arabic', (tester) async {
    await tester.pumpWidget(
        _wrap(const ResumeFormScreen(), locale: const Locale('ar')));
    expect(find.text('المعلومات الشخصية'), findsOneWidget);
    final direction = Directionality.of(
        tester.element(find.byType(ResumeFormScreen)));
    expect(direction, TextDirection.rtl);
  });
}
