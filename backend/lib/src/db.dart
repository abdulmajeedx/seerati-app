import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

bool _overridden = false;

// Servers often ship libsqlite3.so.0 without the dev symlink libsqlite3.so.
void _ensureLibrary() {
  if (_overridden || !Platform.isLinux) return;
  open.overrideFor(OperatingSystem.linux, () {
    try {
      return DynamicLibrary.open('libsqlite3.so');
    } on ArgumentError {
      return DynamicLibrary.open('libsqlite3.so.0');
    }
  });
  _overridden = true;
}

class Db {
  factory Db(String path) {
    _ensureLibrary();
    return Db._(path);
  }

  Db._(String path) : _db = sqlite3.open(path) {
    _db.execute('''
      PRAGMA journal_mode=WAL;
      CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY,
        premium INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS usage (
        device_id TEXT NOT NULL,
        day TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (device_id, day)
      );
      CREATE TABLE IF NOT EXISTS codes (
        code TEXT PRIMARY KEY,
        redeemed_by TEXT,
        redeemed_at TEXT
      );
      CREATE TABLE IF NOT EXISTS job_cache (
        key TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
    ''');
  }

  final Database _db;

  void ensureDevice(String deviceId) {
    _db.execute(
      'INSERT OR IGNORE INTO devices (id, premium, created_at) VALUES (?, 0, ?)',
      [deviceId, DateTime.now().toUtc().toIso8601String()],
    );
  }

  bool isPremium(String deviceId) {
    final rows =
        _db.select('SELECT premium FROM devices WHERE id = ?', [deviceId]);
    return rows.isNotEmpty && rows.first['premium'] == 1;
  }

  /// Job searches are expensive, so identical queries are served from cache
  /// for [maxAge]. Returns null on a miss.
  String? cachedJobs(String key, Duration maxAge) {
    final cutoff =
        DateTime.now().millisecondsSinceEpoch - maxAge.inMilliseconds;
    final rows = _db.select(
      'SELECT payload FROM job_cache WHERE key = ? AND created_at > ?',
      [key, cutoff],
    );
    return rows.isEmpty ? null : rows.first['payload'] as String;
  }

  void cacheJobs(String key, String payload) {
    _db.execute(
      'INSERT INTO job_cache (key, payload, created_at) VALUES (?, ?, ?) '
      'ON CONFLICT(key) DO UPDATE SET payload = excluded.payload, '
      'created_at = excluded.created_at',
      [key, payload, DateTime.now().millisecondsSinceEpoch],
    );
  }

  /// Atomically consumes [cost] AI credits for today (UTC).
  /// Returns false when the daily quota is exhausted.
  bool tryConsumeQuota(String deviceId, int dailyLimit, {int cost = 1}) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    bool ok = false;
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute(
        'INSERT OR IGNORE INTO usage (device_id, day, count) VALUES (?, ?, 0)',
        [deviceId, day],
      );
      final row = _db.select(
        'SELECT count FROM usage WHERE device_id = ? AND day = ?',
        [deviceId, day],
      ).first;
      if ((row['count'] as int) + cost <= dailyLimit) {
        _db.execute(
          'UPDATE usage SET count = count + ? WHERE device_id = ? AND day = ?',
          [cost, deviceId, day],
        );
        ok = true;
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return ok;
  }

  /// Gives back credits consumed by a call that never produced text.
  void refundQuota(String deviceId, {int cost = 1}) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    _db.execute(
      'UPDATE usage SET count = MAX(0, count - ?) '
      'WHERE device_id = ? AND day = ?',
      [cost, deviceId, day],
    );
  }

  /// Single-use redemption: marks the code as used by [deviceId] and grants
  /// premium, atomically. Returns false for unknown or already-used codes
  /// (idempotent success when the same device redeems the same code again).
  bool redeemCode(String code, String deviceId) {
    bool ok = false;
    _db.execute('BEGIN IMMEDIATE');
    try {
      final rows = _db
          .select('SELECT redeemed_by FROM codes WHERE code = ?', [code]);
      if (rows.isNotEmpty) {
        final by = rows.first['redeemed_by'] as String?;
        if (by == null) {
          _db.execute(
            'UPDATE codes SET redeemed_by = ?, redeemed_at = ? WHERE code = ?',
            [deviceId, DateTime.now().toUtc().toIso8601String(), code],
          );
          ok = true;
        } else if (by == deviceId) {
          ok = true;
        }
      }
      if (ok) {
        ensureDevice(deviceId);
        _db.execute(
            'UPDATE devices SET premium = 1 WHERE id = ?', [deviceId]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return ok;
  }

  void insertCode(String code) {
    _db.execute('INSERT OR IGNORE INTO codes (code) VALUES (?)', [code]);
  }

  void dispose() => _db.dispose();
}
