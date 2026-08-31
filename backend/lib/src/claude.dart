import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ClaudeException implements Exception {
  ClaudeException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  bool get retryable => statusCode == 429 || statusCode >= 500;
}

/// Minimal Claude Messages API client (raw HTTP — no official Dart SDK).
class ClaudeClient {
  ClaudeClient({
    required this.apiKey,
    this.mock = false,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String apiKey;

  /// Echoes the prompt instead of calling the API. Tests and local dev only —
  /// a keyless production server must fail loudly, not serve fake text.
  final bool mock;
  final http.Client _http;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-opus-5';

  /// Job search runs a web-search tool loop, which costs ~15x a text call.
  /// Override with SEERATI_JOBS_MODEL to trade quality for reach.
  static String jobsModel(Map<String, String> env) =>
      env['SEERATI_JOBS_MODEL'] ?? _model;

  /// Returns the generated text. When [apiKey] is empty, runs in mock mode
  /// (dev/test without credentials).
  Future<String> generate({
    required String system,
    required String prompt,
    int maxTokens = 2048,
    String? model,
    // The basic web-search variant returns results as plain content blocks the
    // model can read; the 2026 variant routes them through code execution with
    // encrypted stdout, which yields empty answers for this use case.
    int webSearchUses = 0,
  }) async {
    if (mock) return '[MOCK] $system\n---\n$prompt';
    if (apiKey.isEmpty) throw ClaudeException(503, 'ai_unavailable');
    final http.Response response;
    try {
      response = await _http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              // Server-side fallback: on a safety decline the API reruns the
              // request on a fallback model within the same call.
              'anthropic-beta': 'server-side-fallback-2026-07-01',
            },
            body: jsonEncode({
              'model': model ?? _model,
              'max_tokens': maxTokens,
              'fallbacks': 'default',
              'system': system,
              if (webSearchUses > 0)
                'output_config': {'effort': 'low'},
              if (webSearchUses > 0)
                'tools': [
                  {
                    'type': 'web_search_20250305',
                    'name': 'web_search',
                    'max_uses': webSearchUses,
                  }
                ],
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 240));
    } on Exception {
      throw ClaudeException(503, 'upstream_unreachable');
    }
    if (response.statusCode != 200) {
      // A billing or usage-limit refusal is an operator problem, not a user
      // one — surface it as "service unavailable" so the app never tells the
      // user to rephrase a prompt that was fine.
      final detail = _errorMessage(response.body);
      final billing = response.statusCode == 402 ||
          detail.contains('usage limit') ||
          detail.contains('credit balance') ||
          detail.contains('billing');
      stderr.writeln('claude upstream ${response.statusCode}'
          '${billing ? ' (billing/usage limit)' : ''}');
      throw ClaudeException(
          billing ? 503 : response.statusCode, 'ai_unavailable');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    if (body['stop_reason'] == 'refusal') {
      throw ClaudeException(422, 'request_declined');
    }
    final text = (body['content'] as List)
        .cast<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join();
    if (text.trim().isEmpty) throw ClaudeException(502, 'empty_response');
    return text.trim();
  }

  static String _errorMessage(String body) {
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      if (error is Map && error['message'] is String) {
        return (error['message'] as String).toLowerCase();
      }
    } catch (_) {
      // Non-JSON error bodies fall through to the status-code check.
    }
    return '';
  }
}
