// Admin tool — generates activation codes for Seerati.
// Usage: dart run tool/generate_codes.dart [count]
import 'dart:math';

import 'package:seerati/core/utils/activation_codes.dart';

void main(List<String> args) {
  final count = args.isEmpty ? 10 : int.parse(args.first);
  final random = Random.secure();
  for (var i = 0; i < count; i++) {
    // ignore: avoid_print
    print(ActivationCodes.generate(random));
  }
}
