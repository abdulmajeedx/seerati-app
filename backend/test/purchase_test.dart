import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seerati_backend/src/claude.dart';
import 'package:seerati_backend/src/db.dart';
import 'package:seerati_backend/src/handlers.dart';
import 'package:seerati_backend/src/play.dart';
import 'package:seerati_backend/src/refunds.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _appKey = 'test-app-key';
const _product = 'seerati_premium';
const _token = 'kegcmjefjlchcnglpnkpkpco.AO-J1OyXYZ_0123456789';

class _FakePlay implements PlayVerifier {
  Object? result = const PlayPurchase(
    state: PlayPurchaseState.purchased,
    orderId: 'GPA.1',
  );
  final calls = <(String, String)>[];
  Object voided = <VoidedPurchase>[];
  final voidedSince = <DateTime>[];

  @override
  Future<List<VoidedPurchase>> voidedPurchases({
    required DateTime since,
  }) async {
    voidedSince.add(since);
    final v = voided;
    if (v is PlayException) throw v;
    return v as List<VoidedPurchase>;
  }

  @override
  Future<PlayPurchase?> verify(String productId, String token) async {
    calls.add((productId, token));
    final r = result;
    if (r is PlayException) throw r;
    return r as PlayPurchase?;
  }
}

Future<Response> _verify(
  Handler h,
  Map<String, dynamic> body, {
  String? appKey = _appKey,
  String ip = '1.1.1.1',
}) {
  return Future.sync(
    () => h(
      Request(
        'POST',
        Uri.parse('http://localhost/v1/purchase/verify'),
        headers: {
          'content-type': 'application/json',
          'x-forwarded-for': ip,
          if (appKey != null) 'x-app-key': appKey,
        },
        body: jsonEncode(body),
      ),
    ),
  );
}

String _hash(String token) => sha256.convert(utf8.encode(token)).toString();

Future<Response> _entitlement(
  Handler h,
  Map<String, dynamic> body, {
  String? appKey = _appKey,
}) => Future.sync(
  () => h(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/entitlement'),
      headers: {
        'content-type': 'application/json',
        if (appKey != null) 'x-app-key': appKey,
      },
      body: jsonEncode(body),
    ),
  ),
);

Map<String, dynamic> _req({String device = 'dev-1', String token = _token}) => {
  'device_id': device,
  'product_id': _product,
  'purchase_token': token,
};

Future<Map<String, dynamic>> _json(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

Future<Response> _summary(Handler h, String device) => Future.sync(
  () => h(
    Request(
      'POST',
      Uri.parse('http://localhost/v1/ai/summary'),
      headers: {'content-type': 'application/json', 'x-app-key': _appKey},
      body: jsonEncode({'device_id': device, 'job_title': 'x'}),
    ),
  ),
);

void main() {
  late Directory tmp;
  late Db db;
  late _FakePlay play;
  late Handler handler;

  Handler build({PlayVerifier? verifier, ApiConfig? config}) => Api(
    db: db,
    claude: ClaudeClient(apiKey: '', mock: true),
    play: verifier,
    config:
        config ??
        const ApiConfig(
          appKey: _appKey,
          freeDailyQuota: 1,
          freeLifetimeQuota: 0,
          premiumDailyQuota: 5,
        ),
  ).handler;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('seerati_purchase_test');
    db = Db('${tmp.path}/test.db');
    play = _FakePlay();
    handler = build(verifier: play);
  });

  tearDown(() {
    db.dispose();
    tmp.deleteSync(recursive: true);
  });

  group('POST /v1/purchase/verify', () {
    test('a Google-confirmed purchase unlocks premium quota', () async {
      expect(db.isPremium('dev-1'), false);
      final r = await _verify(handler, _req());
      expect(r.statusCode, 200);
      expect((await _json(r))['premium'], true);
      expect(play.calls.single, (_product, _token));
      expect(db.isPremium('dev-1'), true);
      for (var i = 0; i < 5; i++) {
        expect((await _summary(handler, 'dev-1')).statusCode, 200);
      }
    });

    test(
      'an unknown or canceled purchase is refused and grants nothing',
      () async {
        play.result = null;
        final unknown = await _verify(handler, _req());
        expect(unknown.statusCode, 404);
        expect((await _json(unknown))['error'], 'invalid_purchase');

        play.result = const PlayPurchase(
          state: PlayPurchaseState.canceled,
          orderId: 'GPA.2',
        );
        expect((await _verify(handler, _req())).statusCode, 404);
        expect(db.isPremium('dev-1'), false);
      },
    );

    test('a pending purchase is not premium yet', () async {
      play.result = const PlayPurchase(
        state: PlayPurchaseState.pending,
        orderId: '',
      );
      final r = await _verify(handler, _req());
      expect(r.statusCode, 200);
      expect(await _json(r), {'premium': false, 'pending': true});
      expect(db.isPremium('dev-1'), false);
    });

    test('Google being unreachable neither grants nor rejects', () async {
      play.result = const PlayException('HTTP 503');
      final r = await _verify(handler, _req());
      expect(r.statusCode, 503);
      expect((await _json(r))['error'], 'purchases_unavailable');
      expect(db.isPremium('dev-1'), false);
    });

    test('without a configured verifier it fails closed', () async {
      final r = await _verify(build(), _req());
      expect(r.statusCode, 503);
      expect(db.isPremium('dev-1'), false);
    });

    test('verifying the same purchase again is idempotent', () async {
      expect((await _verify(handler, _req())).statusCode, 200);
      expect((await _verify(handler, _req())).statusCode, 200);
      expect(db.isPremium('dev-1'), true);
    });

    test(
      'a purchase serves three devices; a fourth evicts the oldest',
      () async {
        for (final d in ['a', 'b', 'c']) {
          await _verify(handler, _req(device: d));
          await Future<void>.delayed(const Duration(milliseconds: 2));
        }
        expect(['a', 'b', 'c'].map(db.isPremium), [true, true, true]);
        await _verify(handler, _req(device: 'd'));
        expect(['a', 'b', 'c', 'd'].map(db.isPremium), [
          false,
          true,
          true,
          true,
        ]);
      },
    );

    test('eviction never strips premium earned by a redeemed code', () async {
      db.insertCode('CODE1');
      db.redeemCode('CODE1', 'a');
      for (final d in ['a', 'b', 'c', 'd']) {
        await _verify(handler, _req(device: d));
        await Future<void>.delayed(const Duration(milliseconds: 2));
      }
      expect(db.isPremium('a'), true);
    });

    test('rejects malformed input before Google is asked', () async {
      final bad = <Map<String, dynamic>>[
        {..._req(), 'product_id': 'other_product'},
        {..._req(), 'product_id': null},
        {..._req(), 'purchase_token': 'short'},
        {..._req(), 'purchase_token': 'x' * 1025},
        {..._req(), 'purchase_token': 12345678901234567},
        {..._req(), 'device_id': ''},
        {'product_id': _product},
      ];
      for (final body in bad) {
        expect((await _verify(handler, body)).statusCode, 400, reason: '$body');
      }
      expect(play.calls, isEmpty);
    });

    test('requires the app key', () async {
      expect((await _verify(handler, _req(), appKey: null)).statusCode, 401);
      expect((await _verify(handler, _req(), appKey: 'nope')).statusCode, 401);
      expect(play.calls, isEmpty);
    });

    test('an IP gets ten verifications per ten minutes, then 429', () async {
      play.result = null;
      for (var i = 0; i < 10; i++) {
        expect((await _verify(handler, _req())).statusCode, 404);
      }
      expect((await _verify(handler, _req())).statusCode, 429);
      expect(play.calls, hasLength(10));
      expect((await _verify(handler, _req(), ip: '2.2.2.2')).statusCode, 404);
    });
  });


  group('refunds', () {
    test('a voided purchase stops granting premium, codes are unaffected',
        () async {
      await _verify(handler, _req(device: 'a'));
      db.insertCode('CODE2');
      db.redeemCode('CODE2', 'b');
      await _verify(handler, _req(device: 'b'));
      expect(db.isPremium('a'), true);

      expect(db.markVoided(_hash(_token), DateTime.now()), true);
      expect(db.isPremium('a'), false);
      expect(db.isPremium('b'), true);
    });

    test('a voided token is refused without asking Google', () async {
      db.markVoided(_hash(_token), DateTime.now());
      final r = await _verify(handler, _req());
      expect(r.statusCode, 404);
      expect((await _json(r))['error'], 'invalid_purchase');
      expect(play.calls, isEmpty);
      expect(db.isPremium('dev-1'), false);
    });

    test('a refund landing while Google is being asked is not granted',
        () async {
      final slow = _SlowPlay(onVerify: () {
        db.markVoided(_hash(_token), DateTime.now());
      });
      final r = await _verify(build(verifier: slow), _req());
      expect(r.statusCode, 404);
      expect(db.isPremium('dev-1'), false);
    });

    test('markVoided reports only the first time', () {
      expect(db.markVoided('h', DateTime.now()), true);
      expect(db.markVoided('h', DateTime.now()), false);
    });

    test('a new purchase of the same product still works after a refund',
        () async {
      db.markVoided(_hash(_token), DateTime.now());
      const fresh = 'another-token-0123456789-abcdef';
      expect((await _verify(handler, _req(token: fresh))).statusCode, 200);
      expect(db.isPremium('dev-1'), true);
    });
  });

  group('POST /v1/entitlement', () {
    test('reports premium, revoked and free devices', () async {
      await _verify(handler, _req(device: 'buyer'));
      await _verify(handler, _req(device: 'refunded'));
      db.markVoided(_hash(_token), DateTime.now());
      await _verify(handler, _req(device: 'other', token: 'x' * 20));

      expect(await _json(await _entitlement(handler, {'device_id': 'other'})),
          {'premium': true, 'revoked': false});
      expect(await _json(await _entitlement(handler, {'device_id': 'buyer'})),
          {'premium': false, 'revoked': true});
      expect(await _json(await _entitlement(handler, {'device_id': 'nobody'})),
          {'premium': false, 'revoked': false});
    });

    test('a refunded buyer who also holds a code stays premium', () async {
      await _verify(handler, _req(device: 'a'));
      db.insertCode('CODE3');
      db.redeemCode('CODE3', 'a');
      db.markVoided(_hash(_token), DateTime.now());
      expect(await _json(await _entitlement(handler, {'device_id': 'a'})),
          {'premium': true, 'revoked': false});
    });

    test('requires the app key and a device id', () async {
      expect(
        (await _entitlement(handler, {'device_id': 'a'}, appKey: null))
            .statusCode,
        401,
      );
      expect((await _entitlement(handler, {})).statusCode, 400);
      expect((await _entitlement(handler, {'device_id': ''})).statusCode, 400);
    });
  });

  group('RefundSync', () {
    final now = DateTime.utc(2026, 9, 30, 12);
    late RefundSync sync;

    setUp(() => sync = RefundSync(db: db, play: play, clock: () => now));

    test('records voided tokens as hashes and stores the cursor', () async {
      play.voided = [
        const VoidedPurchase(purchaseToken: _token, orderId: 'GPA.1'),
      ];
      await _verify(handler, _req());
      expect(db.isPremium('dev-1'), true);

      expect(await sync.run(), 1);
      expect(db.isPremium('dev-1'), false);
      expect(db.isVoided(_hash(_token)), true);
      expect(db.metaInt(RefundSync.cursorKey), now.millisecondsSinceEpoch);
    });

    test('is idempotent', () async {
      play.voided = [
        const VoidedPurchase(purchaseToken: _token, orderId: 'GPA.1'),
      ];
      expect(await sync.run(), 1);
      expect(await sync.run(), 0);
    });

    test('first run looks back 29 days; later runs overlap by a day',
        () async {
      await sync.run();
      expect(play.voidedSince.last, now.subtract(const Duration(days: 29)));

      final later = now.add(const Duration(hours: 2));
      await RefundSync(db: db, play: play, clock: () => later).run();
      expect(play.voidedSince.last, now.subtract(const Duration(days: 1)));
    });

    test('a cursor older than 29 days is clamped', () async {
      db.setMetaInt(
        RefundSync.cursorKey,
        now.subtract(const Duration(days: 90)).millisecondsSinceEpoch,
      );
      await sync.run();
      expect(play.voidedSince.last, now.subtract(const Duration(days: 29)));
    });

    test('a Google failure keeps the cursor and revokes nothing', () async {
      db.setMetaInt(RefundSync.cursorKey, 1000);
      play.voided = const PlayException('HTTP 503');
      await expectLater(sync.run(), throwsA(isA<PlayException>()));
      expect(db.metaInt(RefundSync.cursorKey), 1000);
    });

    test('a failed run does not block the next one', () async {
      play.voided = const PlayException('HTTP 503');
      await expectLater(sync.run(), throwsA(isA<PlayException>()));
      play.voided = <VoidedPurchase>[];
      expect(await sync.run(), 0);
    });
  });

  group('GooglePlayVerifier', () {
    GooglePlayVerifier verifier(
      Future<http.Response> Function(http.Request) respond,
    ) => GooglePlayVerifier(
      packageName: 'com.example.app',
      clientFactory: () async => MockClient(respond),
    );

    http.Response ok(Map<String, dynamic> body) =>
        http.Response(jsonEncode(body), 200);

    test('queries purchases.products.get with the token encoded', () async {
      late Uri seen;
      final v = verifier((request) async {
        seen = request.url;
        return ok({'purchaseState': 0, 'orderId': 'GPA.9'});
      });
      final p = await v.verify(_product, 'a/b?c#d e%f-0123456789');
      expect(seen.host, 'androidpublisher.googleapis.com');
      expect(
        seen.toString(),
        'https://androidpublisher.googleapis.com/androidpublisher/v3/'
        'applications/com.example.app/purchases/products/$_product/tokens/'
        'a%2Fb%3Fc%23d%20e%25f-0123456789',
      );
      expect(p!.state, PlayPurchaseState.purchased);
      expect(p.orderId, 'GPA.9');
    });

    test('maps purchaseState 0, 1 and 2', () async {
      for (final (code, state) in [
        (0, PlayPurchaseState.purchased),
        (1, PlayPurchaseState.canceled),
        (2, PlayPurchaseState.pending),
      ]) {
        final v = verifier((_) async => ok({'purchaseState': code}));
        expect((await v.verify(_product, _token))!.state, state);
      }
    });

    test('400 and 404 mean the token is not a purchase', () async {
      for (final code in [400, 404]) {
        final v = verifier((_) async => http.Response('{}', code));
        expect(await v.verify(_product, _token), isNull);
      }
    });

    test(
      'auth, quota, server and network failures are PlayException',
      () async {
        for (final code in [401, 403, 429, 500, 503]) {
          final v = verifier((_) async => http.Response('{}', code));
          await expectLater(
            v.verify(_product, _token),
            throwsA(isA<PlayException>()),
            reason: '$code',
          );
        }
        final down = verifier((_) async => throw const SocketException('down'));
        await expectLater(
          down.verify(_product, _token),
          throwsA(isA<PlayException>()),
        );
      },
    );

    test('a 200 without a usable purchaseState is not trusted', () async {
      for (final body in ['{}', '[]', 'not json', '{"purchaseState": 7}']) {
        final v = verifier((_) async => http.Response(body, 200));
        await expectLater(
          v.verify(_product, _token),
          throwsA(isA<PlayException>()),
          reason: body,
        );
      }
    });

    test('lists voided purchases with startTime and follows pages', () async {
      final seen = <Uri>[];
      final v = verifier((request) async {
        seen.add(request.url);
        if (request.url.queryParameters['token'] == null) {
          return ok({
            'voidedPurchases': [
              {'purchaseToken': 'tok-1', 'orderId': 'GPA.1'},
              {'orderId': 'no token'},
              'junk',
            ],
            'tokenPagination': {'nextPageToken': 'page2'},
          });
        }
        return ok({
          'voidedPurchases': [
            {'purchaseToken': 'tok-2', 'orderId': 'GPA.2'},
          ],
        });
      });
      final since = DateTime.utc(2026, 9, 1);
      final list = await v.voidedPurchases(since: since);
      expect(list.map((e) => e.purchaseToken), ['tok-1', 'tok-2']);
      expect(seen, hasLength(2));
      expect(seen.first.path,
          '/androidpublisher/v3/applications/com.example.app/purchases/'
          'voidedpurchases');
      expect(seen.first.queryParameters['startTime'],
          '${since.millisecondsSinceEpoch}');
      expect(seen.last.queryParameters['token'], 'page2');
    });

    test('an empty voided list is fine', () async {
      final v = verifier((_) async => ok({}));
      expect(await v.voidedPurchases(since: DateTime.now()), isEmpty);
    });

    test('voided list failures and endless pages are PlayException', () async {
      for (final code in [401, 403, 429, 500]) {
        final v = verifier((_) async => http.Response('{}', code));
        await expectLater(v.voidedPurchases(since: DateTime.now()),
            throwsA(isA<PlayException>()), reason: '$code');
      }
      final bad = verifier((_) async => http.Response('nope', 200));
      await expectLater(bad.voidedPurchases(since: DateTime.now()),
          throwsA(isA<PlayException>()));
      final endless = verifier((_) async => ok({
            'tokenPagination': {'nextPageToken': 'again'},
          }));
      await expectLater(endless.voidedPurchases(since: DateTime.now()),
          throwsA(isA<PlayException>()));
    });

    test('a failed authentication is retried on the next call', () async {
      var attempts = 0;
      final v = GooglePlayVerifier(
        packageName: 'com.example.app',
        clientFactory: () async {
          if (++attempts == 1) throw StateError('token endpoint down');
          return MockClient((_) async => ok({'purchaseState': 0}));
        },
      );
      await expectLater(
        v.verify(_product, _token),
        throwsA(isA<PlayException>()),
      );
      expect(
        (await v.verify(_product, _token))!.state,
        PlayPurchaseState.purchased,
      );
    });
  });
}

class _SlowPlay implements PlayVerifier {
  _SlowPlay({required this.onVerify});
  final void Function() onVerify;

  @override
  Future<PlayPurchase?> verify(String productId, String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    onVerify();
    return const PlayPurchase(
      state: PlayPurchaseState.purchased,
      orderId: 'GPA.slow',
    );
  }

  @override
  Future<List<VoidedPurchase>> voidedPurchases({required DateTime since}) async =>
      const [];
}
