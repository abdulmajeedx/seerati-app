import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../services/storage_service.dart';

/// null = follow system locale.
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = StorageService.settings.get(AppConstants.localeKey) as String?;
    return code == null ? null : Locale(code);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await StorageService.settings.delete(AppConstants.localeKey);
    } else {
      await StorageService.settings.put(AppConstants.localeKey, locale.languageCode);
    }
  }
}
