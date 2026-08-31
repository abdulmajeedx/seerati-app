import 'dart:convert';
import 'dart:io';

import 'package:seerati_backend/src/claude.dart';
import 'package:seerati_backend/src/db.dart';
import 'package:seerati_backend/src/handlers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
      config: const ApiConfig(
        appKey: _appKey,
        freeDailyQuota: 3,
        freeLifetimeQuota: 0,
      ),
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
      config: const ApiConfig(
        appKey: _appKey,
        freeDailyQuota: 2,
        freeLifetimeQuota: 0,
      ),
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

  test('job search drops entries without a usable url and caches hits',
      () async {
    // A job search costs 12 credits, so this case needs a realistic allowance.
    final jobsHandler = Api(
      db: db,
      claude: ClaudeClient(apiKey: '', mock: true),
      config: const ApiConfig(appKey: _appKey),
    ).handler;
    // Mock mode echoes the prompt, so no JSON array survives parsing.
    final r = await _post(jobsHandler, '/v1/ai/jobs',
        {'device_id': 'j1', 'job_title': 'Flutter', 'city': 'الرياض'});
    expect(r.statusCode, 200);
    expect((await _json(r))['jobs'], isEmpty);

    // A real payload round-trips through the cache; the second call must not
    // spend quota again.
    db.cacheJobs(
      'ar|flutter|الرياض|false',
      jsonEncode([
        {
          'title': 'Flutter Developer',
          'company': 'Acme',
          'location': 'الرياض',
          'url': 'https://example.com/job/1',
          'why_match': 'مطابق لخبرتك',
        }
      ]),
    );
    final hit = await _post(jobsHandler, '/v1/ai/jobs',
        {'device_id': 'j2', 'job_title': 'Flutter', 'city': 'الرياض'});
    final body = await _json(hit);
    expect(body['cached'], true);
    expect((body['jobs'] as List).single['url'], 'https://example.com/job/1');
  });

  test('each ceiling refuses in its own name, outermost first', () async {
    int? spend(String device, String ip, int cost,
        {int daily = 100,
        int lifetime = 0,
        int ipDaily = 1000,
        int global = 1000}) {
      final deny = db.tryConsume(device, ip,
          cost: cost,
          dailyLimit: daily,
          lifetimeLimit: lifetime,
          ipDailyLimit: ipDaily,
          globalDailyLimit: global);
      return deny == null ? null : 1;
    }

    db.ensureDevice('c1');
    // Daily ceiling.
    expect(
        db.tryConsume('c1', '1.1.1.1',
            cost: 12, dailyLimit: 15, lifetimeLimit: 0, ipDailyLimit: 1000, globalDailyLimit: 1000),
        isNull);
    expect(
        db.tryConsume('c1', '1.1.1.1',
            cost: 12, dailyLimit: 15, lifetimeLimit: 0, ipDailyLimit: 1000, globalDailyLimit: 1000),
        Db.denyDaily);

    // Lifetime ceiling bites a fresh device even on day one.
    db.ensureDevice('c2');
    expect(
        db.tryConsume('c2', '2.2.2.2',
            cost: 12, dailyLimit: 100, lifetimeLimit: 10, ipDailyLimit: 1000, globalDailyLimit: 1000),
        Db.denyLifetime);

    // A new device on an exhausted IP is still refused — this is what makes
    // reinstalling the app pointless.
    db.ensureDevice('c3');
    expect(
        db.tryConsume('c3', '3.3.3.3',
            cost: 9, dailyLimit: 100, lifetimeLimit: 0, ipDailyLimit: 10, globalDailyLimit: 1000),
        isNull);
    db.ensureDevice('c4');
    expect(
        db.tryConsume('c4', '3.3.3.3',
            cost: 9, dailyLimit: 100, lifetimeLimit: 0, ipDailyLimit: 10, globalDailyLimit: 1000),
        Db.denyIp);

    // The global ceiling outranks everything.
    db.ensureDevice('c5');
    expect(
        db.tryConsume('c5', '5.5.5.5',
            cost: 5, dailyLimit: 100, lifetimeLimit: 0, ipDailyLimit: 100, globalDailyLimit: 1),
        Db.denyGlobal);
    expect(spend('c9', '9.9.9.9', 1), isNull);
  });

  test('a refused reservation moves no counter', () async {
    db.ensureDevice('r1');
    const args = (daily: 5, ip: 5, global: 5);
    expect(
        db.tryConsume('r1', '7.7.7.7',
            cost: 99,
            dailyLimit: args.daily,
            lifetimeLimit: 0,
            ipDailyLimit: args.ip,
            globalDailyLimit: args.global),
        isNotNull);
    // Nothing was consumed, so the full allowance is still there.
    expect(
        db.remaining('r1', '7.7.7.7',
            dailyLimit: args.daily,
            lifetimeLimit: 0,
            ipDailyLimit: args.ip,
            globalDailyLimit: args.global),
        5);
  });

  test('a refund restores every counter it touched', () async {
    db.ensureDevice('f1');
    expect(
        db.tryConsume('f1', '8.8.8.8',
            cost: 12, dailyLimit: 15, lifetimeLimit: 45, ipDailyLimit: 45, globalDailyLimit: 300),
        isNull);
    db.refund('f1', '8.8.8.8', cost: 12);
    expect(
        db.remaining('f1', '8.8.8.8',
            dailyLimit: 15, lifetimeLimit: 45, ipDailyLimit: 45, globalDailyLimit: 300),
        15);
  });

  test('a billing refusal reads as unavailable, not as a bad prompt', () async {
    // Anthropic answers 400 with an "usage limits" message when the account
    // ceiling is hit; the user's prompt was fine, so the app must not be told
    // to ask them to rephrase.
    final billing = Api(
      db: db,
      claude: ClaudeClient(
        apiKey: 'x',
        httpClient: MockClient((_) async => http.Response(
              jsonEncode({
                'type': 'error',
                'error': {
                  'type': 'invalid_request_error',
                  'message': 'You have reached your specified API usage limits.'
                }
              }),
              400,
            )),
      ),
      config: const ApiConfig(appKey: _appKey),
    ).handler;
    final r = await _post(
        billing, '/v1/ai/summary', {'device_id': 'b1', 'job_title': 'x'});
    expect(r.statusCode, 503);
    expect((await _json(r))['error'], 'ai_unavailable');
  });

  test('the jobs kill switch closes the endpoint and is advertised', () async {
    final off = Api(
      db: db,
      claude: ClaudeClient(apiKey: '', mock: true),
      config: const ApiConfig(appKey: _appKey, jobsEnabled: false),
    ).handler;

    final config = await Future.sync(() => off(
        Request('GET', Uri.parse('http://localhost/v1/config'),
            headers: {'x-app-key': _appKey})));
    expect((await _json(config))['jobs_enabled'], false);

    final blocked = await _post(
        off, '/v1/ai/jobs', {'device_id': 'k1', 'job_title': 'Flutter'});
    expect(blocked.statusCode, 503);
    expect((await _json(blocked))['error'], 'feature_disabled');

    // Disabling job search must not touch the credits of a device that never
    // got a result, nor block the cheaper endpoints.
    final text = await _post(
        off, '/v1/ai/summary', {'device_id': 'k1', 'job_title': 'x'});
    expect(text.statusCode, 200);
    expect((await _json(text))['remaining'], const ApiConfig(appKey: _appKey).freeDailyQuota - 1);
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
