import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seerati/core/services/api_client.dart';

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient(
        httpClient: MockClient(handler),
        baseUrl: 'https://api.test',
        appKey: 'k');

Future<List<JobResult>> _search(ApiClient c) => c.searchJobs(
      language: 'ar',
      jobTitle: 'مطور Flutter',
      city: 'الرياض',
      remote: true,
      skills: const ['Flutter'],
      resumeSummary: 'مهندس برمجيات',
    );

void main() {
  test('parses job results and forwards the search filters', () async {
    late http.Request captured;
    final client = _client((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'cached': false,
          'jobs': [
            {
              'title': 'Flutter Developer',
              'company': 'Acme',
              'location': 'الرياض',
              'url': 'https://example.com/1',
              'why_match': 'مطابق لخبرتك',
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    final jobs = await _search(client);
    expect(jobs, hasLength(1));
    expect(jobs.single.title, 'Flutter Developer');
    expect(jobs.single.whyMatch, 'مطابق لخبرتك');
    expect(jobs.single.url, 'https://example.com/1');

    final sent = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/v1/ai/jobs');
    expect(sent['remote'], true);
    expect(sent['city'], 'الرياض');
    expect(sent['skills'], ['Flutter']);
  });

  test('an empty result set is a normal outcome, not an error', () async {
    final client = _client(
        (_) async => http.Response('{"jobs":[],"cached":false}', 200));
    expect(await _search(client), isEmpty);
  });

  test('missing fields fall back to empty strings', () async {
    final client = _client((_) async => http.Response(
        jsonEncode({
          'jobs': [
            {'title': 'X', 'url': 'https://e.com'}
          ]
        }),
        200));
    final job = (await _search(client)).single;
    expect(job.company, '');
    expect(job.location, '');
    expect(job.whyMatch, '');
  });

  test('a malformed jobs payload surfaces a server error', () async {
    final client =
        _client((_) async => http.Response('{"jobs":"nope"}', 200));
    await expectLater(
      _search(client),
      throwsA(isA<ApiException>()
          .having((e) => e.kind, 'kind', ApiErrorKind.server)),
    );
  });

  test('quota exhaustion is reported with the premium flag', () async {
    final client = _client((_) async =>
        http.Response('{"error":"quota_exhausted","premium":false}', 429));
    try {
      await _search(client);
      fail('expected ApiException');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.quota);
      expect(e.premium, false);
    }
  });
}
