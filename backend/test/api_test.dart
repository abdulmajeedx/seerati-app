import 'dart:convert';
import 'dart:io';

import 'package:seerati_backend/src/claude.dart';
import 'package:seerati_backend/src/db.dart';
import 'package:seerati_backend/src/handlers.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _appKey = 'test-app-key';

Future<Response> _post(Handler handler, String path, Map<String, dynamic> body,
    {String? appKey = _appKey}) {
  return Future.sync(() => handler(Request(
        'POST',
        Uri.parse('http://localhost$path'),
        headers: {
          'content-type': 'application/json',
          if (appKey != null) 'x-app-key': appKey,
        },
        body: jsonEncode(body),
      )));
}

Future<Map<String, dynamic>> _json(Response r) async =>
    jsonDecode(await r.readAsString()) as Map<String, dynamic>;

void main() {
  late Directory tmp;
  late Db db;
  late Handler handler;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('seerati_backend_test');
    db = Db('${tmp.path}/test.db');
    handler = Api(
      db: db,
      claude: ClaudeClient(apiKey: '', mock: true),
      config: const ApiConfig(appKey: _appKey, freeDailyQuota: 3),
    ).handler;
  });

  tearDown(() {
    db.dispose();
    tmp.deleteSync(recursive: true);
  });

  test('health is open, everything else requires the app key', () async {
    final health = await Future.sync(() =>
        handler(Request('GET', Uri.parse('http://localhost/health'))));
    expect(health.statusCode, 200);
    final noKey =
        await _post(handler, '/v1/ai/summary', {'device_id': 'd1'}, appKey: null);
    expect(noKey.statusCode, 401);
    final wrongKey = await _post(handler, '/v1/ai/summary', {'device_id': 'd1'},
        appKey: 'wrong');
    expect(wrongKey.statusCode, 401);
  });

  test('summary returns text in mock mode', () async {
    final r = await _post(handler, '/v1/ai/summary', {
      'device_id': 'd1',
      'language': 'ar',
      'job_title': 'مهندس برمجيات',
      'skills': ['Flutter', 'Dart'],
    });
    expect(r.statusCode, 200);
    expect((await _json(r))['text'], isNotEmpty);
  });

  test('free daily quota is enforced', () async {
    for (var i = 0; i < 3; i++) {
      final r = await _post(handler, '/v1/ai/summary',
          {'device_id': 'q1', 'job_title': 'x'});
      expect(r.statusCode, 200);
    }
    final blocked = await _post(
        handler, '/v1/ai/summary', {'device_id': 'q1', 'job_title': 'x'});
    expect(blocked.statusCode, 429);
    expect((await _json(blocked))['error'], 'quota_exhausted');
    // Other devices are unaffected.
    final other = await _post(
        handler, '/v1/ai/summary', {'device_id': 'q2', 'job_title': 'x'});
    expect(other.statusCode, 200);
  });

  test('code redemption is single-use and grants premium quota', () async {
    db.insertCode('SEERAAAA1111BBBB');
    final ok = await _post(handler, '/v1/redeem',
        {'device_id': 'd1', 'code': 'seer-aaaa-1111-bbbb'});
    expect(ok.statusCode, 200);
    expect((await _json(ok))['premium'], true);
    // Same device again: idempotent success.
    final again = await _post(handler, '/v1/redeem',
        {'device_id': 'd1', 'code': 'SEER-AAAA-1111-BBBB'});
    expect(again.statusCode, 200);
    // Different device: rejected.
    final stolen = await _post(handler, '/v1/redeem',
        {'device_id': 'd2', 'code': 'SEER-AAAA-1111-BBBB'});
    expect(stolen.statusCode, 404);
    // Unknown code: rejected.
    final unknown = await _post(handler, '/v1/redeem',
        {'device_id': 'd3', 'code': 'SEER-ZZZZ-9999-XXXX'});
    expect(unknown.statusCode, 404);
    // Premium device passes the free quota.
    for (var i = 0; i < 10; i++) {
      final r = await _post(handler, '/v1/ai/summary',
          {'device_id': 'd1', 'job_title': 'x'});
      expect(r.statusCode, 200, reason: 'call $i');
    }
  });

  test('a keyless server refuses AI calls and refunds the credit', () async {
    final noKey = Api(
      db: db,
      claude: ClaudeClient(apiKey: ''), // no key, no mock: production-like
      config: const ApiConfig(appKey: _appKey, freeDailyQuota: 2),
    ).handler;
    final r = await _post(
        noKey, '/v1/ai/summary', {'device_id': 'nk', 'job_title': 'x'});
    expect(r.statusCode, 503);
    expect((await _json(r))['error'], 'ai_unavailable');
    // The failed call must not have cost the user a credit: two calls still
    // available on a quota of 2.
    for (var i = 0; i < 2; i++) {
      final ok = await _post(
          handler, '/v1/ai/summary', {'device_id': 'nk', 'job_title': 'x'});
      expect(ok.statusCode, 200, reason: 'call $i');
    }
  });

  test('malformed and oversized input is rejected', () async {
    final noDevice = await _post(handler, '/v1/ai/summary', {'job_title': 'x'});
    expect(noDevice.statusCode, 400);
    final r = await Future.sync(() => handler(Request(
          'POST',
          Uri.parse('http://localhost/v1/ai/summary'),
          headers: {'x-app-key': _appKey},
          body: 'not json',
        )));
    expect(r.statusCode, 400);
    // Oversized field is truncated server-side, not an error.
    final big = await _post(handler, '/v1/ai/cover-letter', {
      'device_id': 'd9',
      'applicant_name': 'x',
      'job_ad': 'y' * 50000,
    });
    expect(big.statusCode, 400); // >32KB body rejected outright
  });
}
