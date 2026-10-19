import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/goora_banner.dart';
import '../data/providers.dart';
import '../domain/direct_pay.dart';
import '../domain/share.dart';
import 'wallet/wallet_controller.dart';

/// A rider's shares a driver marked as not received (007 US3): one warning
/// per share, "عليك X ج.م لـ (name)", with "دفعت" until the rider has said so.
/// Shown on Today and in Wallet; nothing when nothing is owed.
class ShareDebtBanners extends ConsumerWidget {
  const ShareDebtBanners({super.key, this.bottomGap = AppSpacing.gap});

  /// Space under the banners when there are any.
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debts = [
      for (final s in ref.watch(myOpenSharesProvider).value ?? const <Share>[])
        if (s.status.isOpenDebt) s,
    ];
    if (debts.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('share-debts'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in debts) ...[
          GooraBanner(
            key: Key('share-debt-${s.rideId}'),
            kind: GooraBannerKind.warning,
            title: l10n.owesDriver(s.amount, s.otherFirstName),
            body: s.status == ShareStatus.disputed ? l10n.iPaidSent(s.otherFirstName) : l10n.owesDriverBody(s.otherFirstName),
            actionLabel: s.status == ShareStatus.notReceived ? l10n.iPaid : null,
            onAction: s.status == ShareStatus.notReceived
                ? () async {
                    await ref.read(walletRepositoryProvider).claimPaid(s.rideId, s.riderId);
                    ref
                      ..invalidate(myOpenSharesProvider)
                      ..invalidate(walletControllerProvider);
                  }
                : null,
          ),
          SizedBox(height: bottomGap),
        ],
      ],
    );
  }
}
