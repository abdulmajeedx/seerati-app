import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/core/providers/premium_provider.dart';
import 'package:seerati/core/services/purchase_service.dart';
import 'package:seerati/core/services/storage_service.dart';
import 'package:seerati/features/paywall/presentation/paywall_screen.dart';
import 'package:seerati/features/resume/data/models/resume.dart';
import 'package:seerati/features/resume/presentation/template_picker_screen.dart';
import 'package:seerati/l10n/app_localizations.dart';

/// Real store calls hang in the test env, so the paywall provider is
/// overridden with a fixed state.
class _UnavailablePurchaseService extends PurchaseService {
  @override
  PaywallState build() =>
      const PaywallState(status: PaywallStatus.unavailable);
}

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      purchaseServiceProvider.overrideWith(_UnavailablePurchaseService.new),
    ],
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_paywall_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await tmp.delete(recursive: true);
  });

  test('premium flag persists through provider', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(premiumProvider), false);
    await container.read(premiumProvider.notifier).setPremium(true);
    expect(
        StorageService.settings.get(AppConstants.isPremiumKey), true);
    await container.read(premiumProvider.notifier).setPremium(false);
  });

  testWidgets('paywall shows store-unavailable state in test env',
      (tester) async {
    await tester.pumpWidget(_wrap(const PaywallScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
        find.text('The store is not available on this device.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('locked template opens paywall for free users', (tester) async {
    await tester.runAsync(
        () => StorageService.settings.put(AppConstants.isPremiumKey, false));
    final resume = Resume(
      id: 'r1',
      title: 'Test',
      language: 'en',
      personalInfo: PersonalInfo(fullName: 'Ahmed'),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    await tester.pumpWidget(_wrap(TemplatePickerScreen(resume: resume)));
    await tester.tap(find.text('Modern'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PaywallScreen), findsOneWidget);
  });
}
