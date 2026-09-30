import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../providers/premium_provider.dart';
import 'api_client.dart';
import 'purchase_service.dart';
import 'storage_service.dart';

/// Runs once per launch (kept alive by the app root).
final entitlementSyncProvider = FutureProvider<void>(
    (ref) => syncEntitlement(ref, configured: ApiClient.isConfigured));

const _restoreEvery = Duration(hours: 24);

/// Reconciles the local Premium flag with what the server records.
/// - server says premium: unlock locally (reinstall, another device slot).
/// - server says a purchase was refunded and nothing else grants: withdraw.
/// - local premium the server has no record of (bought before purchases were
///   verified): ask Play to re-deliver it so it gets verified, at most daily.
/// An unreachable server changes nothing.
Future<void> syncEntitlement(Ref ref, {required bool configured}) async {
  if (!configured) return;
  // Attach early so Play can re-deliver a payment that was never confirmed.
  ref.read(purchaseServiceProvider);

  final Entitlement server;
  try {
    server = await ref.read(apiClientProvider).fetchEntitlement();
  } on ApiException {
    return;
  }

  final premium = ref.read(premiumProvider.notifier);
  final local = ref.read(premiumProvider);
  if (server.premium) {
    if (!local) await premium.setPremium(true);
    return;
  }
  if (!local) return;
  if (server.revoked) {
    await premium.setPremium(false);
    return;
  }

  final settings = StorageService.settings;
  final last = settings.get(AppConstants.entitlementRestoreAtKey);
  final now = DateTime.now().millisecondsSinceEpoch;
  if (last is int && now - last < _restoreEvery.inMilliseconds) return;
  await settings.put(AppConstants.entitlementRestoreAtKey, now);
  await ref.read(purchaseServiceProvider.notifier).restore(silent: true);
}
