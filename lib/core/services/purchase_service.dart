import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/app_constants.dart';
import '../providers/premium_provider.dart';

enum PaywallStatus { loading, ready, purchasing, unavailable, error }

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
/// Note: with no backend, delivery is device-side only; server receipt
/// validation is out of scope for this offline app.
final purchaseServiceProvider =
    NotifierProvider<PurchaseService, PaywallState>(PurchaseService.new);

class PurchaseService extends Notifier<PaywallState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  PaywallState build() {
    ref.onDispose(() => _sub?.cancel());
    Future.microtask(_init);
    return const PaywallState();
  }

  Future<void> _init() async {
    try {
      final iap = InAppPurchase.instance;
      _sub ??= iap.purchaseStream.listen(
        _onPurchases,
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

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != AppConstants.premiumProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await ref.read(premiumProvider.notifier).setPremium(true);
          state =
              state.copyWith(status: PaywallStatus.ready, justPurchased: true);
        case PurchaseStatus.error:
          state = state.copyWith(status: PaywallStatus.error);
        case PurchaseStatus.canceled:
          state = state.copyWith(status: PaywallStatus.ready);
        case PurchaseStatus.pending:
          state = state.copyWith(status: PaywallStatus.purchasing);
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
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

  Future<void> restore() async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {
      state = state.copyWith(status: PaywallStatus.error);
    }
  }

  void consumeJustPurchased() {
    if (state.justPurchased) state = state.copyWith(justPurchased: false);
  }
}
