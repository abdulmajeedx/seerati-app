import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/core/providers/premium_provider.dart';
import 'package:seerati/core/services/api_client.dart';
import 'package:seerati/core/services/entitlement_sync.dart';
import 'package:seerati/core/services/purchase_service.dart';
import 'package:seerati/core/services/storage_service.dart';

class _Service extends PurchaseService {
  bool built = false;
  final restores = <bool>[];

  @override
  PaywallState build() {
    built = true;
    return const PaywallState(status: PaywallStatus.ready);
  }

  @override
  Future<void> restore({bool silent = false}) async => restores.add(silent);
}

final _configured =
    FutureProvider<void>((ref) => syncEntitlement(ref, configured: true));
final _unconfigured =
    FutureProvider<void>((ref) => syncEntitlement(ref, configured: false));

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_entitlement_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await tmp.delete(recursive: true);
  });

  setUp(() async {
    await StorageService.settings.put(AppConstants.isPremiumKey, false);
    await StorageService.settings.delete(AppConstants.entitlementRestoreAtKey);
  });

  ({ProviderContainer container, _Service service, List<http.Request> sent})
      setup({
    required bool localPremium,
    Future<http.Response> Function(http.Request)? respond,
  }) {
    StorageService.settings.put(AppConstants.isPremiumKey, localPremium);
    final sent = <http.Request>[];
    final service = _Service();
    final container = ProviderContainer(overrides: [
      purchaseServiceProvider.overrideWith(() => service),
      apiClientProvider.overrideWithValue(ApiClient(
        httpClient: MockClient((request) {
          sent.add(request);
          return (respond ?? (_) async => http.Response('{}', 500))(request);
        }),
        baseUrl: 'https://api.test',
        appKey: 'k',
      )),
    ]);
    addTearDown(container.dispose);
    return (container: container, service: service, sent: sent);
  }

  Future<http.Response> Function(http.Request) entitlement(
          {bool premium = false, bool revoked = false}) =>
      (_) async =>
          http.Response(jsonEncode({'premium': premium, 'revoked': revoked}), 200);

  test('a server-recorded purchase unlocks a device that lost its flag',
      () async {
    final t = setup(localPremium: false, respond: entitlement(premium: true));
    await t.container.read(_configured.future);

    expect(t.container.read(premiumProvider), true);
    expect(t.service.restores, isEmpty);
    expect(t.sent.single.url.path, '/v1/entitlement');
  });

  test('a refunded purchase withdraws the local unlock', () async {
    final t = setup(localPremium: true, respond: entitlement(revoked: true));
    await t.container.read(_configured.future);

    expect(t.container.read(premiumProvider), false);
    expect(StorageService.settings.get(AppConstants.isPremiumKey), false);
    expect(t.service.restores, isEmpty);
  });

  test('revoked but already free stays free', () async {
    final t = setup(localPremium: false, respond: entitlement(revoked: true));
    await t.container.read(_configured.future);

    expect(t.container.read(premiumProvider), false);
    expect(t.service.restores, isEmpty);
  });

  test('local premium the server never saw triggers one silent restore a day',
      () async {
    final t = setup(localPremium: true, respond: entitlement());
    await t.container.read(_configured.future);

    expect(t.container.read(premiumProvider), true);
    expect(t.service.restores, [true]);

    t.container.invalidate(_configured);
    await t.container.read(_configured.future);
    expect(t.service.restores, [true], reason: 'throttled within 24h');

    await StorageService.settings.put(
      AppConstants.entitlementRestoreAtKey,
      DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch,
    );
    t.container.invalidate(_configured);
    await t.container.read(_configured.future);
    expect(t.service.restores, [true, true]);
  });

  test('free and unknown to the server: nothing to do, store stays attached',
      () async {
    final t = setup(localPremium: false, respond: entitlement());
    await t.container.read(_configured.future);

    expect(t.container.read(premiumProvider), false);
    expect(t.service.restores, isEmpty);
    expect(t.service.built, true);
  });

  test('an unreachable or refusing server changes nothing', () async {
    for (final respond in <Future<http.Response> Function(http.Request)>[
      (_) async => throw const SocketException('down'),
      (_) async => http.Response('{}', 503),
      (_) async => http.Response('{}', 401),
    ]) {
      final t = setup(localPremium: true, respond: respond);
      await t.container.read(_configured.future);
      expect(t.container.read(premiumProvider), true);
      expect(t.service.restores, isEmpty);

      final free = setup(localPremium: false, respond: respond);
      await free.container.read(_configured.future);
      expect(free.container.read(premiumProvider), false);
    }
  });

  test('builds without a backend make no requests and touch nothing',
      () async {
    final t = setup(localPremium: true, respond: entitlement(revoked: true));
    await t.container.read(_unconfigured.future);

    expect(t.sent, isEmpty);
    expect(t.container.read(premiumProvider), true);
    expect(t.service.built, false);
  });
}
