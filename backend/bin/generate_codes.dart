// Admin tool — generates single-use activation codes into the server DB.
// Usage: dart run bin/generate_codes.dart [count] [dbPath]
import 'dart:math';

import 'package:seerati_backend/src/db.dart';

const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

void main(List<String> args) {
  final count = args.isNotEmpty ? int.parse(args[0]) : 10;
  final dbPath = args.length > 1 ? args[1] : 'data/seerati.db';
  final db = Db(dbPath);
  final random = Random.secure();
  for (var i = 0; i < count; i++) {
    final chars = List.generate(
        12, (_) => _alphabet[random.nextInt(_alphabet.length)]).join();
    final code = 'SEER${chars.substring(0, 4)}'
        '${chars.substring(4, 8)}${chars.substring(8)}';
    db.insertCode(code);
    // ignore: avoid_print
    print('SEER-${chars.substring(0, 4)}-'
        '${chars.substring(4, 8)}-${chars.substring(8)}');
  }
  db.dispose();
}
