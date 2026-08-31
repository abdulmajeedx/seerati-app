import 'package:flutter/material.dart';

import '../core/services/api_client.dart';
import '../features/paywall/presentation/paywall_screen.dart';
import '../l10n/app_localizations.dart';

/// One place that turns an [ApiException] into what the user sees, so every
/// AI entry point reports the same limit in the same words.
extension ApiExceptionMessage on ApiException {
  String message(AppLocalizations l10n) => switch (kind) {
        ApiErrorKind.network => l10n.networkError,
        ApiErrorKind.quota =>
          premium ? l10n.quotaExhaustedPremium : l10n.quotaExhausted,
        ApiErrorKind.lifetimeQuota => l10n.lifetimeQuotaExhausted,
        ApiErrorKind.ipLimited => l10n.ipLimited,
        ApiErrorKind.serviceBusy => l10n.serviceBusy,
        ApiErrorKind.declined => l10n.aiDeclined,
        ApiErrorKind.unauthorized || ApiErrorKind.server => l10n.errorGeneric,
      };

  /// Upgrading only helps when a free-tier ceiling is what refused the call.
  bool get suggestsUpgrade =>
      !premium &&
      (kind == ApiErrorKind.quota || kind == ApiErrorKind.lifetimeQuota);
}

void showApiError(BuildContext context, ApiException error) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(error.message(l10n)),
      action: error.suggestsUpgrade
          ? SnackBarAction(
              label: l10n.upgradeForMore,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              ),
            )
          : null,
    ));
}
