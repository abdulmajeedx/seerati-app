import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/core/providers/premium_provider.dart';
import 'package:seerati/core/services/api_client.dart';
import 'package:seerati/core/services/purchase_service.dart';
import 'package:seerati/core/services/storage_service.dart';

class _Service extends PurchaseService {
  _Service({required this.serverVerify});

  final bool serverVerify;
  final completed = <String>[];

  @override
  PaywallState build() => const PaywallState(status: PaywallStatus.ready);

  @override
  bool get verifyOnServer => serverVerify;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.purchaseID ?? '');
}

PurchaseDetails _purchase({
  PurchaseStatus status = PurchaseStatus.purchased,
  String productId = AppConstants.premiumProductId,
  String source = 'google_play',
  String token = 'token-0123456789abcdef',
}) =>
    PurchaseDetails(
      purchaseID: 'order-1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: token,
        source: source,
      ),
      transactionDate: '0',
      status: status,
    )..pendingCompletePurchase = true;

void main() {
  late Directory tmp;

  setUpAll(() async {
    tmp = await Directory.systemTemp.createTemp('seerati_purchase_svc_test');
    await StorageService.init(path: tmp.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close().timeout(const Duration(seconds: 5));
    } catch (_) {}
    await tmp.delete(recursive: true);
  });

  setUp(() => StorageService.settings.put(AppConstants.isPremiumKey, false));

  ({ProviderContainer container, _Service service, List<http.Request> sent})
      setup({
    bool serverVerify = true,
    Future<http.Response> Function(http.Request)? respond,
  }) {
    final sent = <http.Request>[];
    final service = _Service(serverVerify: serverVerify);
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
    container.read(purchaseServiceProvider); // attaches the notifier
    return (container: container, service: service, sent: sent);
  }

  http.Response json(int code, Map<String, dynamic> body) =>
      http.Response(jsonEncode(body), code);

  test('a server-verified purchase unlocks premium and is completed',
      () async {
    final t = setup(respond: (_) async => json(200, {'premium': true}));
    await t.service.onPurchases([_purchase()]);

    expect(t.container.read(premiumProvider), true);
    expect(t.container.read(purchaseServiceProvider).justPurchased, true);
    expect(t.service.completed, ['order-1']);
    final body = jsonDecode(t.sent.single.body) as Map<String, dynamic>;
    expect(t.sent.single.url.path, '/v1/purchase/verify');
    expect(body['purchase_token'], 'token-0123456789abcdef');
    expect(body['product_id'], AppConstants.premiumProductId);
  });

  test('re-delivering a purchase already unlocked does not celebrate again',
      () async {
    final t = setup(respond: (_) async => json(200, {'premium': true}));
    await StorageService.settings.put(AppConstants.isPremiumKey, true);
    t.container.invalidate(premiumProvider);
    await t.service.onPurchases([_purchase(status: PurchaseStatus.restored)]);

    expect(t.container.read(premiumProvider), true);
    expect(t.container.read(purchaseServiceProvider).justPurchased, false);
    expect(t.service.completed, ['order-1']);
  });

  test('a purchase the server rejects unlocks nothing and stays pending',
      () async {
    final t = setup(respond: (_) async => json(404, {'error': 'x'}));
    await t.service.onPurchases([_purchase()]);

    expect(t.container.read(premiumProvider), false);
    expect(
        t.container.read(purchaseServiceProvider).status, PaywallStatus.unverified);
    expect(t.service.completed, isEmpty);
  });

  test('an unreachable server unlocks nothing and stays pending', () async {
    final t = setup(respond: (_) async => throw const SocketException('down'));
    await t.service.onPurchases([_purchase(status: PurchaseStatus.restored)]);

    expect(t.container.read(premiumProvider), false);
    expect(
        t.container.read(purchaseServiceProvider).status, PaywallStatus.unverified);
    expect(t.service.completed, isEmpty);
  });

  test('a purchase Google still lists as pending unlocks nothing', () async {
    final t = setup(
        respond: (_) async => json(200, {'premium': false, 'pending': true}));
    await t.service.onPurchases([_purchase()]);

    expect(t.container.read(premiumProvider), false);
    expect(
        t.container.read(purchaseServiceProvider).status, PaywallStatus.purchasing);
    expect(t.service.completed, isEmpty);
  });

  test('only Google Play receipts can be verified', () async {
    final t = setup(respond: (_) async => json(200, {'premium': true}));
    await t.service.onPurchases([_purchase(source: 'app_store')]);

    expect(t.container.read(premiumProvider), false);
    expect(t.sent, isEmpty);
    expect(t.service.completed, isEmpty);
  });

  test('other products are ignored entirely', () async {
    final t = setup(respond: (_) async => json(200, {'premium': true}));
    await t.service.onPurchases([_purchase(productId: 'something_else')]);

    expect(t.container.read(premiumProvider), false);
    expect(t.sent, isEmpty);
    expect(t.service.completed, isEmpty);
  });

  test('offline builds (no backend) still grant on the store\'s word',
      () async {
    final t = setup(serverVerify: false);
    await t.service.onPurchases([_purchase()]);

    expect(t.container.read(premiumProvider), true);
    expect(t.sent, isEmpty);
    expect(t.service.completed, ['order-1']);
  });
}
