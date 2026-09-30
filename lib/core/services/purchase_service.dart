import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/app_constants.dart';
import '../providers/premium_provider.dart';
import 'api_client.dart';

/// [unverified]: the store took payment but the server has not confirmed it
/// yet, so nothing is unlocked and the purchase stays pending for a retry.
enum PaywallStatus {
  loading,
  ready,
  purchasing,
  unavailable,
  error,
  unverified,
}

class PaywallState {
  const PaywallState({
    this.status = PaywallStatus.loading,
    this.product,
    this.justPurchased = false,
  });

  final PaywallStatus status;
  final ProductDetails? product;
  final bool justPurchased;

  PaywallState copyWith({
    PaywallStatus? status,
    ProductDetails? product,
    bool? justPurchased,
  }) =>
      PaywallState(
        status: status ?? this.status,
        product: product ?? this.product,
        justPurchased: justPurchased ?? this.justPurchased,
      );
}

/// Single entry point for all purchase logic. The premium flag itself is
/// persisted by [premiumProvider].
/// With a backend configured, a purchase unlocks nothing until the server has
/// checked it with Google. Builds without a backend are offline-only and grant
/// on the store's word alone.
final purchaseServiceProvider =
    NotifierProvider<PurchaseService, PaywallState>(PurchaseService.new);

class PurchaseService extends Notifier<PaywallState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Future<void>? _initFuture;

  @override
  PaywallState build() {
    ref.onDispose(() => _sub?.cancel());
    _initFuture = Future.microtask(_init);
    return const PaywallState();
  }

  Future<void> _init() async {
    try {
      final iap = InAppPurchase.instance;
      _sub ??= iap.purchaseStream.listen(
        onPurchases,
        onError: (Object _) =>
            state = state.copyWith(status: PaywallStatus.error),
      );
      if (!await iap.isAvailable()) {
        state = state.copyWith(status: PaywallStatus.unavailable);
        return;
      }
      final response = await iap
          .queryProductDetails(const {AppConstants.premiumProductId});
      if (response.productDetails.isEmpty) {
        state = state.copyWith(status: PaywallStatus.unavailable);
        return;
      }
      state = PaywallState(
          status: PaywallStatus.ready,
          product: response.productDetails.first);
    } catch (_) {
      state = state.copyWith(status: PaywallStatus.unavailable);
    }
  }

  Future<void> retry() => _init();

  /// Store integration point; overridden in tests.
  @protected
  Future<void> completePurchase(PurchaseDetails purchase) =>
      InAppPurchase.instance.completePurchase(purchase);

  @protected
  bool get verifyOnServer => ApiClient.isConfigured;

  @visibleForTesting
  Future<void> onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != AppConstants.premiumProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Left unacknowledged on failure: the store redelivers it on the
          // next launch or restore, and refunds it if it never completes.
          if (!await _confirmed(purchase)) continue;
          final wasPremium = ref.read(premiumProvider);
          await ref.read(premiumProvider.notifier).setPremium(true);
          state = state.copyWith(
              status: PaywallStatus.ready, justPurchased: !wasPremium);
        case PurchaseStatus.error:
          state = state.copyWith(status: PaywallStatus.error);
        case PurchaseStatus.canceled:
          state = state.copyWith(status: PaywallStatus.ready);
        case PurchaseStatus.pending:
          state = state.copyWith(status: PaywallStatus.purchasing);
      }
      if (purchase.pendingCompletePurchase) await completePurchase(purchase);
    }
  }

  Future<bool> _confirmed(PurchaseDetails purchase) async {
    if (!verifyOnServer) return true;
    if (purchase.verificationData.source != 'google_play') {
      state = state.copyWith(status: PaywallStatus.unverified);
      return false;
    }
    try {
      final verdict = await ref.read(apiClientProvider).verifyPurchase(
            productId: purchase.productID,
            purchaseToken: purchase.verificationData.serverVerificationData,
          );
      if (verdict == PurchaseVerdict.verified) return true;
      state = state.copyWith(status: PaywallStatus.purchasing);
    } on ApiException {
      state = state.copyWith(status: PaywallStatus.unverified);
    }
    return false;
  }

  Future<void> buy() async {
    final product = state.product;
    if (product == null || state.status == PaywallStatus.purchasing) return;
    state = state.copyWith(status: PaywallStatus.purchasing);
    try {
      await InAppPurchase.instance.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product));
    } catch (_) {
      state = state.copyWith(status: PaywallStatus.error);
    }
  }

  /// [silent] is for background recovery: no error state, and a purchase that
  /// was already unlocked locally does not celebrate again.
  Future<void> restore({bool silent = false}) async {
    try {
      // The stream must be attached before the store re-delivers purchases.
      await (_initFuture ?? Future<void>.value());
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      if (!silent) state = state.copyWith(status: PaywallStatus.error);
    }
  }

  void consumeJustPurchased() {
    if (state.justPurchased) state = state.copyWith(justPurchased: false);
  }
}
