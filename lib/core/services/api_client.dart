import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

enum ApiErrorKind { network, quota, declined, unauthorized, server }

class ApiException implements Exception {
  const ApiException(this.kind, {this.premium = false});
  final ApiErrorKind kind;
  final bool premium;
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Talks to the Seerati backend, which holds the Claude API key. Configured at
/// build time: --dart-define=SEERATI_API_BASE=... --dart-define=SEERATI_APP_KEY=...
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl, String? appKey})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _envBase,
        _appKey = appKey ?? _envKey,
        _deviceId = baseUrl == null ? null : 'test-device';

  final http.Client _http;
  final String _baseUrl;
  final String _appKey;

  static const _envBase = String.fromEnvironment('SEERATI_API_BASE');
  static const _envKey = String.fromEnvironment('SEERATI_APP_KEY');
  static const _deviceIdKey = 'device_id';
  static const _timeout = Duration(seconds: 120);

  /// AI features stay hidden in builds without a configured backend.
  static bool get isConfigured => _envBase.isNotEmpty && _envKey.isNotEmpty;

  bool get _configured => _baseUrl.isNotEmpty && _appKey.isNotEmpty;

  String? _deviceId;

  Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    const storage = FlutterSecureStorage();
    var id = await storage.read(key: _deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await storage.write(key: _deviceIdKey, value: id);
    }
    return _deviceId = id;
  }

  Future<String> improveSummary({
    required String language,
    required String jobTitle,
    required List<String> skills,
    required String currentSummary,
  }) =>
      _text('/v1/ai/summary', {
        'language': language,
        'job_title': jobTitle,
        'skills': skills,
        'current_summary': currentSummary,
      });

  Future<String> rewriteExperience({
    required String language,
    required String jobTitle,
    required String company,
    required String rawDescription,
  }) =>
      _text('/v1/ai/experience', {
        'language': language,
        'job_title': jobTitle,
        'company': company,
        'raw_description': rawDescription,
      });

  Future<String> coverLetterFromAd({
    required String language,
    required String applicantName,
    required String jobTitle,
    required String company,
    required String jobAd,
    required String resumeSummary,
  }) =>
      _text('/v1/ai/cover-letter', {
        'language': language,
        'applicant_name': applicantName,
        'job_title': jobTitle,
        'company': company,
        'job_ad': jobAd,
        'resume_summary': resumeSummary,
      });

  /// Server-side single-use redemption. Returns true when premium is granted.
  Future<bool> redeem(String code) async {
    final body = await _post('/v1/redeem', {'code': code});
    return body['premium'] == true;
  }

  Future<String> _text(String path, Map<String, dynamic> payload) async {
    final body = await _post(path, payload);
    final text = body['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const ApiException(ApiErrorKind.server);
    }
    return text.trim();
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> payload) async {
    if (!_configured) throw const ApiException(ApiErrorKind.server);
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {
              'content-type': 'application/json; charset=utf-8',
              'x-app-key': _appKey,
            },
            body: jsonEncode({...payload, 'device_id': await deviceId()}),
          )
          .timeout(_timeout);
    } catch (_) {
      throw const ApiException(ApiErrorKind.network);
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }
    switch (response.statusCode) {
      case 200:
        return body;
      case 401:
        throw const ApiException(ApiErrorKind.unauthorized);
      case 404:
        throw const ApiException(ApiErrorKind.declined);
      case 422:
        throw const ApiException(ApiErrorKind.declined);
      case 429:
        throw ApiException(ApiErrorKind.quota, premium: body['premium'] == true);
      default:
        throw const ApiException(ApiErrorKind.server);
    }
  }
}
