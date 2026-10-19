import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/widgets/goora_ghost_button.dart';
import '../../../core/widgets/goora_status_chip.dart';
import '../data/providers.dart';
import '../domain/cash_mark.dart';
import '../domain/direct_pay.dart';
import 'wallet/wallet_controller.dart';

/// One passenger after drop-off, on the driver's side (004 FR-012, 007 US2):
/// "استلمت N ج" / "ماستلمتش" while unanswered, then a status chip with
/// "غيّر" while `SharePolicy.canMark` still allows the other answer. The
/// share is paid outside Goora; this only records the driver's answer. Used
/// for group rides and offered trips alike.
class ShareMarkRow extends ConsumerWidget {
  const ShareMarkRow({
    super.key,
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.riderName,
    required this.date,
    required this.fallbackAmount,
  });

  final String rideId;
  final String riderId;
  final String driverId;

  /// First name only — riders who boarded (003 FR-016).
  final String riderName;
  final CalendarDate date;

  /// The share to show before the derived one loads.
  final int fallbackAmount;

  Future<void> _record(WidgetRef ref, CashOutcome outcome, int amount) async {
    await ref.read(walletRepositoryProvider).markShare(CashMark(
          rideId: rideId,
          riderId: riderId,
          driverId: driverId,
          outcome: outcome,
          amount: amount,
          date: date,
        ));
    ref
      ..invalidate(driverShareProvider(rideId, riderId))
      ..invalidate(walletControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final share = ref.watch(driverShareProvider(rideId, riderId)).value;
    final amount = share?.amount ?? fallbackAmount;
    final status = share?.status ?? ShareStatus.pending;
    final now = ref.watch(nowProvider)();
    bool can(CashOutcome outcome) =>
        share != null &&
        SharePolicy.canMark(
          current: status,
          outcome: outcome,
          tripEnd: SharePolicy.minuteOf(share.tripEnd),
          now: SharePolicy.minuteOf(now),
          reversedOnce: share.reversedOnce,
        );
    final other = status == ShareStatus.received || status == ShareStatus.autoReceived
        ? CashOutcome.didNotPay
        : CashOutcome.received;
    return Padding(
      key: Key('cash-$riderId'),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(riderName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          if (status == ShareStatus.pending)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GooraGhostButton(
                  key: Key('cash-received-$riderId'),
                  label: l10n.cashReceived(amount),
                  onPressed: () => _record(ref, CashOutcome.received, amount),
                ),
                const SizedBox(height: AppSpacing.sm),
                GooraGhostButton(
                  key: Key('cash-unpaid-$riderId'),
                  label: l10n.didNotPay,
                  onPressed: () => _record(ref, CashOutcome.didNotPay, amount),
                ),
              ],
            )
          else
            Row(
              children: [
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: switch (status) {
                      ShareStatus.received => GooraStatusChip(status: GooraStatus.covered, label: l10n.cashMarkedReceived),
                      ShareStatus.autoReceived =>
                        GooraStatusChip(status: GooraStatus.covered, label: l10n.shareAutoReceived),
                      ShareStatus.disputed => GooraStatusChip(status: GooraStatus.waiting, label: l10n.shareDisputed(riderName)),
                      _ => GooraStatusChip(status: GooraStatus.off, label: l10n.cashMarkedUnpaid),
                    },
                  ),
                ),
                if (can(other))
                  TextButton(
                    key: Key('cash-change-$riderId'),
                    style: TextButton.styleFrom(minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch)),
                    onPressed: () => _record(ref, other, amount),
                    child: Text(
                      other == CashOutcome.received ? l10n.cashReceived(amount) : l10n.didNotPay,
                      style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
