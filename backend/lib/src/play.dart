import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

enum PlayPurchaseState { purchased, pending, canceled }

class PlayPurchase {
  const PlayPurchase({required this.state, required this.orderId});

  final PlayPurchaseState state;

  /// Empty while a purchase is still pending.
  final String orderId;
}

/// Google could not be asked (credentials, network, 5xx). Says nothing about
/// whether the purchase is genuine, so callers must not grant or reject.
class PlayException implements Exception {
  const PlayException(this.message);
  final String message;

  @override
  String toString() => 'PlayException: $message';
}

class VoidedPurchase {
  const VoidedPurchase({required this.purchaseToken, required this.orderId});

  final String purchaseToken;
  final String orderId;
}

abstract interface class PlayVerifier {
  /// Null when Google does not know this token for [productId].
  Future<PlayPurchase?> verify(String productId, String token);

  /// Purchases refunded, charged back or otherwise voided since [since].
  /// Google only reports the last 30 days.
  Future<List<VoidedPurchase>> voidedPurchases({required DateTime since});
}

/// Google Play Developer API `purchases.products.get` for one-time products.
class GooglePlayVerifier implements PlayVerifier {
  GooglePlayVerifier({
    required this.packageName,
    required Future<http.Client> Function() clientFactory,
    this.timeout = const Duration(seconds: 10),
  }) : _clientFactory = clientFactory;

  /// Reads the key eagerly so a bad file fails at startup; the OAuth client
  /// itself is created on first use and retried after a failure.
  factory GooglePlayVerifier.serviceAccountFile(
    String path, {
    required String packageName,
  }) {
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(File(path).readAsStringSync()),
    );
    return GooglePlayVerifier(
      packageName: packageName,
      clientFactory: () => clientViaServiceAccount(credentials, [_scope]),
    );
  }

  static const _scope = 'https://www.googleapis.com/auth/androidpublisher';
  static const _host = 'androidpublisher.googleapis.com';

  final String packageName;
  final Duration timeout;
  final Future<http.Client> Function() _clientFactory;
  Future<http.Client>? _client;

  Future<http.Client> _ensureClient() {
    return _client ??= _clientFactory().catchError((Object e) {
      _client = null;
      throw PlayException('cannot authenticate: ${e.runtimeType}');
    });
  }

  @override
  Future<PlayPurchase?> verify(String productId, String token) async {
    final client = await _ensureClient();
    // productId and packageName come from server config; the token is the only
    // untrusted segment and is fully percent-encoded.
    final uri = Uri.parse(
      'https://$_host/androidpublisher/v3/applications/'
      '$packageName/purchases/products/$productId/tokens/'
      '${Uri.encodeComponent(token)}',
    );
    final http.Response response;
    try {
      response = await client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const PlayException('timeout');
    } catch (e) {
      if (e is PlayException) rethrow;
      throw PlayException('request failed: ${e.runtimeType}');
    }

    if (response.statusCode == 404 || response.statusCode == 400) {
      stderr.writeln(
        'play: HTTP ${response.statusCode} '
        '${_reason(response.body)}',
      );
      return null;
    }
    if (response.statusCode != 200) {
      throw PlayException(
        'HTTP ${response.statusCode} '
        '${_reason(response.body)}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const PlayException('unparseable response');
    }
    if (decoded is! Map) throw const PlayException('unexpected response');
    final state = switch (decoded['purchaseState']) {
      0 => PlayPurchaseState.purchased,
      1 => PlayPurchaseState.canceled,
      2 => PlayPurchaseState.pending,
      _ => throw const PlayException('missing purchaseState'),
    };
    final orderId = decoded['orderId'];
    return PlayPurchase(
      state: state,
      orderId: orderId is String ? orderId : '',
    );
  }

  static const _maxVoidedPages = 20;

  @override
  Future<List<VoidedPurchase>> voidedPurchases({required DateTime since}) async {
    final client = await _ensureClient();
    final voided = <VoidedPurchase>[];
    String? pageToken;
    for (var page = 0; page < _maxVoidedPages; page++) {
      final uri = Uri.https(
        _host,
        '/androidpublisher/v3/applications/$packageName/purchases/'
        'voidedpurchases',
        {
          'startTime': '${since.millisecondsSinceEpoch}',
          'maxResults': '1000',
          if (pageToken != null) 'token': pageToken,
        },
      );
      final http.Response response;
      try {
        response = await client.get(uri).timeout(timeout);
      } on TimeoutException {
        throw const PlayException('timeout');
      } catch (e) {
        throw PlayException('request failed: ${e.runtimeType}');
      }
      if (response.statusCode != 200) {
        throw PlayException('HTTP ${response.statusCode} '
            '${_reason(response.body)}');
      }
      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        throw const PlayException('unparseable response');
      }
      if (decoded is! Map) throw const PlayException('unexpected response');
      final items = decoded['voidedPurchases'];
      if (items is List) {
        for (final item in items) {
          if (item is! Map) continue;
          final token = item['purchaseToken'];
          if (token is! String || token.isEmpty) continue;
          final orderId = item['orderId'];
          voided.add(VoidedPurchase(
            purchaseToken: token,
            orderId: orderId is String ? orderId : '',
          ));
        }
      }
      final pagination = decoded['tokenPagination'];
      final next = pagination is Map ? pagination['nextPageToken'] : null;
      if (next is! String || next.isEmpty) return voided;
      pageToken = next;
    }
    throw const PlayException('too many voided-purchase pages');
  }

  static String _reason(String body) {
    try {
      final error = (jsonDecode(body) as Map)['error'];
      if (error is Map) {
        final errors = error['errors'];
        final reason =
            errors is List && errors.isNotEmpty && errors.first is Map
            ? (errors.first as Map)['reason']
            : null;
        return '${error['status'] ?? ''} ${reason ?? ''}'.trim();
      }
    } catch (_) {}
    return '';
  }
}
