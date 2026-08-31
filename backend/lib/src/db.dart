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

  /// Atomically consumes one AI-call credit for today (UTC).
  /// Returns false when the daily quota is exhausted.
  bool tryConsumeQuota(String deviceId, int dailyLimit) {
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
      if ((row['count'] as int) < dailyLimit) {
        _db.execute(
          'UPDATE usage SET count = count + 1 WHERE device_id = ? AND day = ?',
          [deviceId, day],
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

  /// Gives back a credit consumed by a call that never produced text.
  void refundQuota(String deviceId) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    _db.execute(
      'UPDATE usage SET count = count - 1 '
      'WHERE device_id = ? AND day = ? AND count > 0',
      [deviceId, day],
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
