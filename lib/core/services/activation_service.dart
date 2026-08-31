import '../utils/activation_codes.dart';
import 'storage_service.dart';

abstract final class ActivationService {
  static const _attemptsKey = 'activation_attempts';
  static const _redeemedKey = 'redeemed_codes';
  static const maxAttemptsPerMinute = 5;

  static bool isRateLimited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts =
        (StorageService.settings.get(_attemptsKey) as List?)?.cast<int>() ??
            const [];
    return attempts.where((t) => now - t < 60000).length >=
        maxAttemptsPerMinute;
  }

  /// Records the attempt, then validates. Premium itself is granted by the
  /// caller through premiumProvider.
  static Future<bool> redeem(String code) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final attempts =
        ((StorageService.settings.get(_attemptsKey) as List?)?.cast<int>() ??
                const <int>[])
            .where((t) => now - t < 60000)
            .toList()
          ..add(now);
    await StorageService.settings.put(_attemptsKey, attempts);
    if (!ActivationCodes.isValid(code)) return false;
    final redeemed =
        ((StorageService.settings.get(_redeemedKey) as List?)?.cast<String>() ??
                const <String>[])
            .toList();
    final normalized = ActivationCodes.normalize(code);
    if (!redeemed.contains(normalized)) {
      redeemed.add(normalized);
      await StorageService.settings.put(_redeemedKey, redeemed);
    }
    return true;
  }
}
