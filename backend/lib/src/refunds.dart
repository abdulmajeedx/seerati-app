import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'db.dart';
import 'play.dart';

/// Pulls Google's voided-purchases list into [Db] so a refund or chargeback
/// stops granting Premium. Idempotent: each run re-reads a day of overlap.
class RefundSync {
  RefundSync({required this.db, required this.play, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final Db db;
  final PlayVerifier play;
  final DateTime Function() _clock;

  static const cursorKey = 'voided_synced_at';
  static const overlap = Duration(days: 1);

  // Google rejects a startTime older than 30 days.
  static const _horizon = Duration(days: 29);

  bool _running = false;

  /// Returns how many purchases were newly recorded as voided. On failure the
  /// cursor stays put, so the next run covers the same window again.
  Future<int> run() async {
    if (_running) return 0;
    _running = true;
    try {
      final now = _clock();
      final floor = now.subtract(_horizon);
      final last = db.metaInt(cursorKey);
      var since = last == null
          ? floor
          : DateTime.fromMillisecondsSinceEpoch(last, isUtc: true)
              .subtract(overlap);
      if (since.isBefore(floor)) since = floor;

      var fresh = 0;
      for (final v in await play.voidedPurchases(since: since)) {
        final hash = sha256.convert(utf8.encode(v.purchaseToken)).toString();
        if (db.markVoided(hash, now)) {
          fresh++;
          stdout.writeln('purchase voided order=${v.orderId} '
              'token=${hash.substring(0, 8)}');
        }
      }
      db.setMetaInt(cursorKey, now.millisecondsSinceEpoch);
      return fresh;
    } finally {
      _running = false;
    }
  }
}
