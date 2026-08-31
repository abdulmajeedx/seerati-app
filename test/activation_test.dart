import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seerati/core/services/activation_service.dart';
import 'package:seerati/core/services/storage_service.dart';
import 'package:seerati/core/utils/activation_codes.dart';

void main() {
  group('ActivationCodes', () {
    test('generated codes validate', () {
      final random = Random(42);
      for (var i = 0; i < 50; i++) {
        final code = ActivationCodes.generate(random);
        expect(ActivationCodes.isValid(code), true, reason: code);
        expect(ActivationCodes.isValid(code.toLowerCase()), true);
        expect(ActivationCodes.isValid(code.replaceAll('-', ' ')), true);
      }
    });

    test('tampered and garbage codes fail', () {
      final code = ActivationCodes.generate(Random(1));
      final tampered =
          code.substring(0, code.length - 1) + (code.endsWith('A') ? 'B' : 'A');
      expect(ActivationCodes.isValid(tampered), false);
      expect(ActivationCodes.isValid(''), false);
      expect(ActivationCodes.isValid('SEER-AAAA-BBBB-CCCC'), false);
      expect(ActivationCodes.isValid('XXXX-AB12-CD34-EF56'), false);
      expect(ActivationCodes.isValid('A' * 500), false);
    });
  });

  group('ActivationService', () {
    late Directory tmp;

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('seerati_activation');
      await StorageService.init(path: tmp.path);
    });

    tearDownAll(() async {
      await Hive.close();
      await tmp.delete(recursive: true);
    });

    test('valid code redeems, invalid does not', () async {
      expect(await ActivationService.redeem('garbage'), false);
      final code = ActivationCodes.generate(Random(7));
      expect(await ActivationService.redeem(code), true);
    });

    test('rate limited after max attempts in a minute', () async {
      for (var i = 0; i < ActivationService.maxAttemptsPerMinute; i++) {
        await ActivationService.redeem('wrong-$i');
      }
      expect(ActivationService.isRateLimited(), true);
    });
  });
}
