import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Offline activation codes: `SEER-XXXX-XXXX-YYYY` where YYYY is an
/// HMAC-SHA256 signature of the 8-char payload. Pure Dart on purpose so
/// tool/generate_codes.dart can run it without Flutter.
/// The secret ships inside the APK, so this deters casual guessing only —
/// accepted trade-off for a fully offline app.
abstract final class ActivationCodes {
  static const _secret =
      'f3a91c7e42d8b06519ce84a7d2f0b3e6a15c9d48720eb361';
  // No easily-confused characters (I, L, O, 0, 1).
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  static String _sign(String payload) {
    final mac =
        Hmac(sha256, utf8.encode(_secret)).convert(utf8.encode(payload)).bytes;
    return List.generate(4, (i) => _alphabet[mac[i] % _alphabet.length])
        .join();
  }

  static bool isValid(String input) {
    if (input.length > 64) return false;
    final raw = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (raw.length != 16 || !raw.startsWith('SEER')) return false;
    final payload = raw.substring(4, 12);
    return _sign(payload) == raw.substring(12);
  }

  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String generate(Random random) {
    final payload = List.generate(
        8, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
    return 'SEER-${payload.substring(0, 4)}-${payload.substring(4)}-'
        '${_sign(payload)}';
  }
}
