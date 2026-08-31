import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'claude.dart';
import 'db.dart';
import 'prompts.dart' as prompts;

class ApiConfig {
  const ApiConfig({
    required this.appKey,
    this.freeDailyQuota = 5,
    this.premiumDailyQuota = 50,
  });

  final String appKey;
  final int freeDailyQuota;
  final int premiumDailyQuota;
}

class Api {
  Api({required this.db, required this.claude, required this.config});

  final Db db;
  final ClaudeClient claude;
  final ApiConfig config;

  // Per-IP burst limiter: sliding one-minute window.
  final Map<String, List<int>> _ipHits = {};
  static const _ipLimitPerMinute = 30;

  Handler get handler {
    final router = Router()
      ..get('/health', (Request r) => _json(200, {'ok': true}))
      ..post('/v1/redeem', _redeem)
      ..post('/v1/ai/summary', _aiSummary)
      ..post('/v1/ai/experience', _aiExperience)
      ..post('/v1/ai/cover-letter', _aiCoverLetter);
    return const Pipeline().addMiddleware(_guard).addHandler(router.call);
  }

  Middleware get _guard => (inner) => (request) async {
        if (request.url.path == 'health') return inner(request);
        if (request.headers['x-app-key'] != config.appKey) {
          return _json(401, {'error': 'unauthorized'});
        }
        final ip = _clientIp(request);
        final now = DateTime.now().millisecondsSinceEpoch;
        final hits = (_ipHits[ip] ?? [])
          ..removeWhere((t) => now - t > 60000)
          ..add(now);
        _ipHits[ip] = hits;
        if (hits.length > _ipLimitPerMinute) {
          return _json(429, {'error': 'rate_limited'});
        }
        return inner(request);
      };

  String _clientIp(Request request) =>
      request.headers['x-forwarded-for']?.split(',').first.trim() ??
      (request.context['shelf.io.connection_info'] as dynamic)
          ?.remoteAddress
          ?.address as String? ??
      'unknown';

  Future<Response> _redeem(Request request) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'bad_request'});
    final deviceId = _str(body, 'device_id', 64);
    final code = _str(body, 'code', 64)
        .toUpperCase()
        .replaceAll(RegExp('[^A-Z0-9]'), '');
    if (deviceId.isEmpty || code.isEmpty) {
      return _json(400, {'error': 'bad_request'});
    }
    final ok = db.redeemCode(code, deviceId);
    if (!ok) return _json(404, {'error': 'invalid_code'});
    return _json(200, {'premium': true});
  }

  Future<Response> _aiSummary(Request request) => _aiCall(request, (body) {
        final language = _language(body);
        return (
          prompts.summarySystem(language),
          prompts.summaryPrompt(
            jobTitle: _str(body, 'job_title', 120),
            skills: _strList(body, 'skills', 30, 60),
            currentSummary: _str(body, 'current_summary', 1500),
          ),
        );
      });

  Future<Response> _aiExperience(Request request) => _aiCall(request, (body) {
        final language = _language(body);
        return (
          prompts.experienceSystem(language),
          prompts.experiencePrompt(
            jobTitle: _str(body, 'job_title', 120),
            company: _str(body, 'company', 120),
            rawDescription: _str(body, 'raw_description', 3000),
          ),
        );
      });

  Future<Response> _aiCoverLetter(Request request) => _aiCall(request, (body) {
        final language = _language(body);
        return (
          prompts.coverLetterSystem(language),
          prompts.coverLetterPrompt(
            applicantName: _str(body, 'applicant_name', 120),
            jobTitle: _str(body, 'job_title', 120),
            company: _str(body, 'company', 120),
            jobAd: _str(body, 'job_ad', 6000),
            resumeSummary: _str(body, 'resume_summary', 1500),
          ),
        );
      });

  Future<Response> _aiCall(Request request,
      (String, String) Function(Map<String, dynamic>) build) async {
    final body = await _body(request);
    if (body == null) return _json(400, {'error': 'bad_request'});
    final deviceId = _str(body, 'device_id', 64);
    if (deviceId.isEmpty) return _json(400, {'error': 'bad_request'});
    db.ensureDevice(deviceId);
    final premium = db.isPremium(deviceId);
    final limit = premium ? config.premiumDailyQuota : config.freeDailyQuota;
    if (!db.tryConsumeQuota(deviceId, limit)) {
      return _json(429, {'error': 'quota_exhausted', 'premium': premium});
    }
    final (system, prompt) = build(body);
    try {
      final text = await claude.generate(system: system, prompt: prompt);
      return _json(200, {'text': text});
    } on ClaudeException catch (e) {
      // The user got no text, so the credit goes back.
      db.refundQuota(deviceId);
      return _json(e.statusCode >= 500 || e.statusCode == 429 ? 503 : 422,
          {'error': e.message});
    }
  }

  static Future<Map<String, dynamic>?> _body(Request request) async {
    final raw = await request.readAsString();
    if (raw.length > 32 * 1024) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String _language(Map<String, dynamic> body) =>
      body['language'] == 'en' ? 'en' : 'ar';

  static String _str(Map<String, dynamic> body, String key, int maxLen) {
    final value = body[key];
    if (value is! String) return '';
    final trimmed = value.trim();
    return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
  }

  static List<String> _strList(
      Map<String, dynamic> body, String key, int maxItems, int maxLen) {
    final value = body[key];
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) => s.length > maxLen ? s.substring(0, maxLen) : s)
        .take(maxItems)
        .toList();
  }

  static Response _json(int status, Map<String, dynamic> body) =>
      Response(status,
          body: jsonEncode(body),
          headers: {'content-type': 'application/json; charset=utf-8'});
}
