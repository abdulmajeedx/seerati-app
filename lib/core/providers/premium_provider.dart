import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// Stub until in-app purchase (phase 5) wires the real flow.
final premiumProvider = NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() =>
      StorageService.settings.get(AppConstants.isPremiumKey, defaultValue: false)
          as bool;

  Future<void> setPremium(bool value) async {
    state = value;
    await StorageService.settings.put(AppConstants.isPremiumKey, value);
  }
}
