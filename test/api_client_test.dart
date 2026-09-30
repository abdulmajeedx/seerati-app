import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seerati/core/services/api_client.dart';

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(
      httpClient: MockClient(handler),
      baseUrl: 'https://api.test',
      appKey: 'k',
    );

ApiClient _status(int code, [Map<String, dynamic> body = const {}]) =>
    _client((_) async => http.Response(jsonEncode(body), code,
        headers: {'content-type': 'application/json'}));

Matcher _throwsKind(ApiErrorKind kind) => throwsA(
    isA<ApiException>().having((e) => e.kind, 'kind', kind));

Future<String> _call(ApiClient c) => c.improveSummary(
    language: 'ar', jobTitle: 'مهندس', skills: const ['Flutter'], currentSummary: '');

void main() {
  test('sends device id, app key and payload; returns trimmed text', () async {
    late http.Request captured;
    final client = _client((request) async {
      captured = request;
      return http.Response(jsonEncode({'text': '  نص  '}), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    expect(await _call(client), 'نص');
    expect(captured.headers['x-app-key'], 'k');
    expect(captured.url.toString(), 'https://api.test/v1/ai/summary');
    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent['device_id'], isNotEmpty);
    expect(sent['skills'], ['Flutter']);
    expect(sent['language'], 'ar');
  });

  test('maps every backend status to its error kind', () async {
    await expectLater(_call(_status(401)), _throwsKind(ApiErrorKind.unauthorized));
    await expectLater(_call(_status(404)), _throwsKind(ApiErrorKind.declined));
    await expectLater(_call(_status(422)), _throwsKind(ApiErrorKind.declined));
    await expectLater(_call(_status(429)), _throwsKind(ApiErrorKind.quota));
    await expectLater(_call(_status(500)), _throwsKind(ApiErrorKind.server));
    await expectLater(_call(_status(503)), _throwsKind(ApiErrorKind.server));
  });

  test('quota error carries the premium flag for the right message', () async {
    try {
      await _call(_status(429, {'premium': true}));
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.quota);
      expect(e.premium, true);
    }
  });

  test('network failure and malformed body do not leak raw exceptions', () async {
    final offline = _client((_) async => throw http.ClientException('down'));
    await expectLater(_call(offline), _throwsKind(ApiErrorKind.network));

    final garbage = _client((_) async => http.Response('not json', 200));
    await expectLater(_call(garbage), _throwsKind(ApiErrorKind.server));

    final blank = _client((_) async => http.Response('{"text":"   "}', 200));
    await expectLater(_call(blank), _throwsKind(ApiErrorKind.server));
  });

  test('redeem reports the server verdict', () async {
    final granted = _client(
        (_) async => http.Response(jsonEncode({'premium': true}), 200));
    expect(await granted.redeem('SEER-AAAA-BBBB-CCCC'), true);

    final rejected = _client((_) async => http.Response('{}', 404));
    await expectLater(rejected.redeem('SEER-XXXX-YYYY-ZZZZ'),
        _throwsKind(ApiErrorKind.declined));
  });

  test('verifyPurchase sends the token and maps the server verdict', () async {
    late http.Request captured;
    final verified = _client((request) async {
      captured = request;
      return http.Response(jsonEncode({'premium': true}), 200);
    });
    expect(
        await verified.verifyPurchase(
            productId: 'seerati_premium', purchaseToken: 'tok-0123456789abcdef'),
        PurchaseVerdict.verified);
    expect(captured.url.path, '/v1/purchase/verify');
    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(sent['purchase_token'], 'tok-0123456789abcdef');
    expect(sent['product_id'], 'seerati_premium');
    expect(sent['device_id'], isNotEmpty);

    final pending = _status(200, {'premium': false, 'pending': true});
    expect(
        await pending.verifyPurchase(
            productId: 'seerati_premium', purchaseToken: 'tok-0123456789abcdef'),
        PurchaseVerdict.pending);

    final forged = _status(404);
    await expectLater(
        forged.verifyPurchase(
            productId: 'seerati_premium', purchaseToken: 'tok-0123456789abcdef'),
        _throwsKind(ApiErrorKind.declined));
    final down = _status(503, {'error': 'purchases_unavailable'});
    await expectLater(
        down.verifyPurchase(
            productId: 'seerati_premium', purchaseToken: 'tok-0123456789abcdef'),
        _throwsKind(ApiErrorKind.server));
  });

  test('fetchEntitlement maps premium and revoked, defaulting to false',
      () async {
    late http.Request captured;
    final client = _client((request) async {
      captured = request;
      return http.Response(jsonEncode({'premium': false, 'revoked': true}), 200);
    });
    final e = await client.fetchEntitlement();
    expect(e.premium, false);
    expect(e.revoked, true);
    expect(captured.url.path, '/v1/entitlement');
    expect((jsonDecode(captured.body) as Map)['device_id'], isNotEmpty);

    final bare = await _status(200).fetchEntitlement();
    expect(bare.premium, false);
    expect(bare.revoked, false);

    await expectLater(
        _status(503).fetchEntitlement(), _throwsKind(ApiErrorKind.server));
    await expectLater(_status(401).fetchEntitlement(),
        _throwsKind(ApiErrorKind.unauthorized));
  });

  test('unconfigured builds never open a socket', () async {
    var called = false;
    final client = ApiClient(
      httpClient: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
      baseUrl: '',
      appKey: '',
    );
    await expectLater(_call(client), _throwsKind(ApiErrorKind.server));
    expect(called, false);
    expect(ApiClient.isConfigured, false);
  });
}
