import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../commute/domain/group.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/cash_mark.dart';
import '../../../wallet/domain/seat_price.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../domain/ride.dart';

/// One cash rider after drop-off: "Received N EGP cash" / "Didn't pay", then
/// a status. The label and the recorded [CashMark.amount] both read
/// [SeatPrice.cash], so they always match what the rider was shown (005
/// FR-029).
class CashReceivedRow extends ConsumerWidget {
  const CashReceivedRow({super.key, required this.ride, required this.member, required this.price});

  final Ride ride;
  final Member member;
  final SeatPrice price;

  /// The cash amount; the contribution only if no multiple of 5 fits, which
  /// the demo corridor never hits.
  int get _amount => price.cash ?? price.contribution;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final outcome = ref.watch(cashStatusProvider(ride.id, member.id)).value?.outcome;
    return Padding(
      key: Key('cash-${member.id}'),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(member.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          if (outcome != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: outcome == CashOutcome.received
                  ? GooraStatusChip(status: GooraStatus.covered, label: l10n.cashMarkedReceived)
                  : GooraStatusChip(status: GooraStatus.off, label: l10n.cashMarkedUnpaid),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GooraGhostButton(
                    key: Key('cash-received-${member.id}'),
                    label: l10n.cashReceived(_amount),
                    onPressed: () => _record(ref, CashOutcome.received),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GooraGhostButton(
                    key: Key('cash-unpaid-${member.id}'),
                    label: l10n.didNotPay,
                    onPressed: () => _record(ref, CashOutcome.didNotPay),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _record(WidgetRef ref, CashOutcome outcome) async {
    await ref.read(walletRepositoryProvider).markCash(CashMark(
          rideId: ride.id,
          riderId: member.id,
          driverId: ride.driverId!,
          outcome: outcome,
          amount: _amount,
          date: ride.date,
        ));
    ref
      ..invalidate(cashStatusProvider(ride.id, member.id))
      ..invalidate(walletControllerProvider);
  }
}
