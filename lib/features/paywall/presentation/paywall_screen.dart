import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/premium_provider.dart';
import '../../../core/services/purchase_service.dart';
import '../../../l10n/app_localizations.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final premium = ref.watch(premiumProvider);
    final paywall = ref.watch(purchaseServiceProvider);

    ref.listen(purchaseServiceProvider, (previous, next) {
      if (next.justPurchased) {
        ref.read(purchaseServiceProvider.notifier).consumeJustPurchased();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.purchaseSuccess)));
        Navigator.of(context).maybePop();
      } else if (next.status == PaywallStatus.error &&
          previous?.status != PaywallStatus.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: premium
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_outlined,
                        size: 64, color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(l10n.alreadyPremium,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              )
            : _PaywallBody(paywall: paywall),
      ),
    );
  }
}

class _PaywallBody extends ConsumerWidget {
  const _PaywallBody({required this.paywall});

  final PaywallState paywall;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final service = ref.read(purchaseServiceProvider.notifier);

    if (paywall.status == PaywallStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.workspace_premium_outlined,
            size: 72, color: scheme.primary),
        const SizedBox(height: 24),
        for (final benefit in [
          l10n.premiumBenefit1,
          l10n.premiumBenefit2,
          l10n.premiumBenefit3,
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 22, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(benefit,
                        style: Theme.of(context).textTheme.bodyLarge)),
              ],
            ),
          ),
        const Spacer(),
        if (paywall.status == PaywallStatus.unavailable) ...[
          Text(
            l10n.storeUnavailable,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: service.retry,
            child: Text(l10n.retry),
          ),
        ] else ...[
          FilledButton(
            onPressed:
                paywall.status == PaywallStatus.purchasing ? null : service.buy,
            child: paywall.status == PaywallStatus.purchasing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Text(paywall.product == null
                    ? l10n.buyNow
                    : '${l10n.buyNow} — ${paywall.product!.price}'),
          ),
          TextButton(
            onPressed: service.restore,
            child: Text(l10n.restorePurchases),
          ),
        ],
      ],
    );
  }
}
