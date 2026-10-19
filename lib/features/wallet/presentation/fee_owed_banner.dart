import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/widgets/goora_banner.dart';
import 'labels.dart';
import 'wallet/pay_sheet.dart';
import 'wallet/wallet_controller.dart';

/// What the rider owes Goora for its own fees (008 US1–US3): "عليك X ج.م
/// لـ Goora" with Pay. Calm while within the grace (with the due date once
/// due); a warning once overdue, when booking is blocked. Nothing when
/// nothing is owed. Used on Wallet and, when overdue, on Today.
class FeeOwedBanner extends ConsumerWidget {
  const FeeOwedBanner({super.key, this.onlyWhenOverdue = false, this.bottomGap = 0});

  /// Today shows it only once it blocks booking.
  final bool onlyWhenOverdue;
  final double bottomGap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider).value?.wallet;
    if (wallet == null || wallet.owed == 0) return const SizedBox.shrink();
    if (onlyWhenOverdue && !wallet.feeOverdue) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final due = wallet.feeDue;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: bottomGap),
      child: GooraBanner(
        key: const Key('fee-owed'),
        kind: wallet.feeOverdue ? GooraBannerKind.warning : GooraBannerKind.info,
        title: l10n.feeOwed(wallet.owed),
        body: wallet.feeOverdue
            ? l10n.feeOverdueBody
            : (due != null ? l10n.feeDueLine(l10n.shortDate(due)) : l10n.feeOwedBody),
        actionLabel: l10n.payNow,
        onAction: () => showPaySheet(context, PayPurpose.settle),
      ),
    );
  }
}
