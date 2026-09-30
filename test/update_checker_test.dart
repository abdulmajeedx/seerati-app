import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seerati/core/constants/app_constants.dart';
import 'package:seerati/features/update/data/update_checker.dart';

http.Client _github(Object body, {int status = 200}) =>
    MockClient((_) async => http.Response(jsonEncode(body), status));

Map<String, Object?> _release(String tag, {List<String> assets = const []}) => {
  'tag_name': tag,
  'draft': false,
  'prerelease': false,
  'html_url': 'https://github.com/x/y/releases/tag/$tag',
  'assets': [
    for (final a in assets) {'browser_download_url': a},
  ],
};

void main() {
  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!;
    expect(AppConstants.appVersion, version.group(1));
  });

  test('versions compare numerically, not as text', () {
    expect(UpdateChecker.compareVersions('2.10.0', '2.9.1'), greaterThan(0));
    expect(UpdateChecker.compareVersions('2.5', '2.5.0'), 0);
    expect(UpdateChecker.compareVersions('2.4.9', '2.5.0'), lessThan(0));
  });

  test('a newer release is offered with its APK', () async {
    final update = await UpdateChecker.check(
      current: '2.5.0',
      client: _github(
        _release(
          'v2.6.0',
          assets: [
            'https://example.com/notes.txt',
            'https://e.com/seerati.apk',
          ],
        ),
      ),
    );
    expect(update?.version, '2.6.0');
    expect(update?.downloadUrl.toString(), 'https://e.com/seerati.apk');
  });

  test('without an APK the release page is used', () async {
    final update = await UpdateChecker.check(
      current: '2.5.0',
      client: _github(_release('v2.6.0')),
    );
    expect(update?.downloadUrl.path, '/x/y/releases/tag/v2.6.0');
  });

  test('same or older versions, drafts and failures offer nothing', () async {
    expect(
      await UpdateChecker.check(
        current: '2.5.0',
        client: _github(_release('v2.5.0')),
      ),
      isNull,
    );
    expect(
      await UpdateChecker.check(
        current: '2.5.0',
        client: _github(_release('v2.4.0')),
      ),
      isNull,
    );
    expect(
      await UpdateChecker.check(
        current: '2.5.0',
        client: _github({..._release('v9.0.0'), 'prerelease': true}),
      ),
      isNull,
    );
    expect(
      await UpdateChecker.check(
        current: '2.5.0',
        client: _github({'message': 'rate'}, status: 403),
      ),
      isNull,
    );
    expect(
      await UpdateChecker.check(
        current: '2.5.0',
        client: MockClient((_) async => throw const SocketException('off')),
      ),
      isNull,
    );
  });
}
