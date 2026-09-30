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
      CREATE TABLE IF NOT EXISTS ip_usage (
        ip TEXT NOT NULL,
        day TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (ip, day)
      );
      CREATE TABLE IF NOT EXISTS global_usage (
        day TEXT PRIMARY KEY,
        count INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS purchases (
        token_hash TEXT NOT NULL,
        device_id TEXT NOT NULL,
        order_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (token_hash, device_id)
      );
      CREATE INDEX IF NOT EXISTS purchases_device ON purchases (device_id);
      CREATE TABLE IF NOT EXISTS voided_purchases (
        token_hash TEXT PRIMARY KEY,
        voided_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
    // Added in 2.2.0; older databases predate the column.
    final columns = _db
        .select('PRAGMA table_info(devices)')
        .map((r) => r['name'] as String);
    if (!columns.contains('lifetime_used')) {
      _db.execute(
          'ALTER TABLE devices ADD COLUMN lifetime_used INTEGER NOT NULL '
          'DEFAULT 0');
    }
  }

  final Database _db;

  void ensureDevice(String deviceId) {
    _db.execute(
      'INSERT OR IGNORE INTO devices (id, premium, created_at) VALUES (?, 0, ?)',
      [deviceId, DateTime.now().toUtc().toIso8601String()],
    );
  }

  /// Premium comes from a redeemed code (`devices.premium`) or from a Play
  /// purchase bound to this device. Deriving it keeps revocation a plain row
  /// delete.
  bool isPremium(String deviceId) {
    final rows = _db.select(
      'SELECT EXISTS(SELECT 1 FROM devices WHERE id = ? AND premium = 1) '
      'OR EXISTS(SELECT 1 FROM purchases p WHERE p.device_id = ? AND '
      'p.token_hash NOT IN (SELECT token_hash FROM voided_purchases)) '
      'AS premium',
      [deviceId, deviceId],
    );
    return rows.first['premium'] == 1;
  }

  /// True when a purchase this device relied on was refunded or charged back,
  /// so the app can withdraw its local unlock too.
  bool hasVoidedPurchase(String deviceId) => _db.select(
        'SELECT 1 FROM purchases p JOIN voided_purchases v '
        'ON v.token_hash = p.token_hash WHERE p.device_id = ? LIMIT 1',
        [deviceId],
      ).isNotEmpty;

  bool isVoided(String tokenHash) => _db.select(
        'SELECT 1 FROM voided_purchases WHERE token_hash = ?',
        [tokenHash],
      ).isNotEmpty;

  /// Returns true the first time [tokenHash] is recorded as voided.
  bool markVoided(String tokenHash, DateTime at) {
    _db.execute(
      'INSERT OR IGNORE INTO voided_purchases (token_hash, voided_at) '
      'VALUES (?, ?)',
      [tokenHash, at.millisecondsSinceEpoch],
    );
    return _db.updatedRows == 1;
  }

  int? metaInt(String key) {
    final rows = _db.select('SELECT value FROM meta WHERE key = ?', [key]);
    return rows.isEmpty ? null : int.tryParse(rows.first['value'] as String);
  }

  void setMetaInt(String key, int value) {
    _db.execute(
      'INSERT INTO meta (key, value) VALUES (?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, '$value'],
    );
  }

  /// Binds a Google-verified purchase (identified by the SHA-256 of its token)
  /// to [deviceId]. One purchase may serve at most [maxDevices] devices at a
  /// time; binding another evicts the oldest, so reinstalling always works but
  /// a token shared around loses its earliest users. Returns how many devices
  /// were evicted.
  int bindPurchase(
    String tokenHash,
    String deviceId,
    String orderId, {
    required int maxDevices,
  }) {
    var evicted = 0;
    _db.execute('BEGIN IMMEDIATE');
    try {
      ensureDevice(deviceId);
      final existing = _db.select(
          'SELECT 1 FROM purchases WHERE token_hash = ? AND device_id = ?',
          [tokenHash, deviceId]);
      if (existing.isEmpty) {
        _db.execute(
          'INSERT INTO purchases (token_hash, device_id, order_id, created_at) '
          'VALUES (?, ?, ?, ?)',
          [tokenHash, deviceId, orderId, DateTime.now().millisecondsSinceEpoch],
        );
        final count = _db.select(
            'SELECT COUNT(*) AS n FROM purchases WHERE token_hash = ?',
            [tokenHash]).first['n'] as int;
        if (count > maxDevices) {
          evicted = count - maxDevices;
          _db.execute(
            'DELETE FROM purchases WHERE rowid IN ('
            'SELECT rowid FROM purchases WHERE token_hash = ? '
            'ORDER BY created_at ASC, rowid ASC LIMIT ?)',
            [tokenHash, evicted],
          );
        }
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return evicted;
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

  /// Why a spend request was refused; null means it was granted.
  /// Checked outermost-first so the answer names the binding limit.
  static const denyGlobal = 'service_busy';
  static const denyIp = 'ip_limited';
  static const denyLifetime = 'lifetime_exhausted';
  static const denyDaily = 'quota_exhausted';

  /// Atomically reserves [cost] credits against every applicable ceiling.
  /// Either all counters move or none do, so a partial spend can't leak.
  String? tryConsume(
    String deviceId,
    String ip, {
    required int cost,
    required int dailyLimit,
    required int lifetimeLimit,
    required int ipDailyLimit,
    required int globalDailyLimit,
  }) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    String? deny;
    _db.execute('BEGIN IMMEDIATE');
    try {
      _db.execute(
          'INSERT OR IGNORE INTO global_usage (day, count) VALUES (?, 0)',
          [day]);
      final global = _db.select(
          'SELECT count FROM global_usage WHERE day = ?', [day]).first;
      if ((global['count'] as int) + cost > globalDailyLimit) {
        deny = denyGlobal;
      }

      if (deny == null) {
        _db.execute(
            'INSERT OR IGNORE INTO ip_usage (ip, day, count) VALUES (?, ?, 0)',
            [ip, day]);
        final ipRow = _db.select(
            'SELECT count FROM ip_usage WHERE ip = ? AND day = ?',
            [ip, day]).first;
        if ((ipRow['count'] as int) + cost > ipDailyLimit) deny = denyIp;
      }

      if (deny == null && lifetimeLimit > 0) {
        final device = _db.select(
            'SELECT lifetime_used FROM devices WHERE id = ?', [deviceId]);
        final used =
            device.isEmpty ? 0 : device.first['lifetime_used'] as int;
        if (used + cost > lifetimeLimit) deny = denyLifetime;
      }

      if (deny == null) {
        _db.execute(
            'INSERT OR IGNORE INTO usage (device_id, day, count) '
            'VALUES (?, ?, 0)',
            [deviceId, day]);
        final row = _db.select(
            'SELECT count FROM usage WHERE device_id = ? AND day = ?',
            [deviceId, day]).first;
        if ((row['count'] as int) + cost > dailyLimit) deny = denyDaily;
      }

      if (deny == null) {
        _db
          ..execute(
              'UPDATE usage SET count = count + ? WHERE device_id = ? AND day = ?',
              [cost, deviceId, day])
          ..execute(
              'UPDATE ip_usage SET count = count + ? WHERE ip = ? AND day = ?',
              [cost, ip, day])
          ..execute('UPDATE global_usage SET count = count + ? WHERE day = ?',
              [cost, day])
          ..execute(
              'UPDATE devices SET lifetime_used = lifetime_used + ? WHERE id = ?',
              [cost, deviceId]);
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
    return deny;
  }

  /// Credits left for [deviceId] today, after every ceiling.
  int remaining(
    String deviceId,
    String ip, {
    required int dailyLimit,
    required int lifetimeLimit,
    required int ipDailyLimit,
    required int globalDailyLimit,
  }) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    int used(String sql, List<Object?> args) {
      final rows = _db.select(sql, args);
      return rows.isEmpty ? 0 : rows.first.values.first as int? ?? 0;
    }

    final limits = <int>[
      dailyLimit -
          used('SELECT count FROM usage WHERE device_id = ? AND day = ?',
              [deviceId, day]),
      ipDailyLimit -
          used('SELECT count FROM ip_usage WHERE ip = ? AND day = ?', [ip, day]),
      globalDailyLimit -
          used('SELECT count FROM global_usage WHERE day = ?', [day]),
      if (lifetimeLimit > 0)
        lifetimeLimit -
            used('SELECT lifetime_used FROM devices WHERE id = ?', [deviceId]),
    ];
    final min = limits.reduce((a, b) => a < b ? a : b);
    return min < 0 ? 0 : min;
  }

  /// Gives back credits reserved for a call that never produced text.
  void refund(String deviceId, String ip, {int cost = 1}) {
    final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    _db
      ..execute(
          'UPDATE usage SET count = MAX(0, count - ?) '
          'WHERE device_id = ? AND day = ?',
          [cost, deviceId, day])
      ..execute(
          'UPDATE ip_usage SET count = MAX(0, count - ?) '
          'WHERE ip = ? AND day = ?',
          [cost, ip, day])
      ..execute(
          'UPDATE global_usage SET count = MAX(0, count - ?) WHERE day = ?',
          [cost, day])
      ..execute(
          'UPDATE devices SET lifetime_used = MAX(0, lifetime_used - ?) '
          'WHERE id = ?',
          [cost, deviceId]);
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
