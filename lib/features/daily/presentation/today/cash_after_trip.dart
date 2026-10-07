import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../commute/domain/group.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/cash_mark.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../domain/check_in.dart';
import '../../domain/ride.dart';
import 'today_controller.dart';

/// After drop-off, each picked-up cash-trial rider gets "Received N EGP
/// cash" / "Didn't pay", then a status (004 v2 FR-012). Names are already
/// visible here — only riders who boarded are listed (003 FR-016). Nothing
/// shows when nobody on the trip pays cash.
class CashAfterTrip extends ConsumerWidget {
  const CashAfterTrip({super.key, required this.view, required this.leg});

  final TodayView view;
  final LegPlan leg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ride = leg.ride!;
    final boarded = [
      for (final o in leg.outcomes)
        if (o.outcome == Outcome.pickedUp) view.group!.member(o.personId),
    ].whereType<Member>().toList();
    final cashRiders = [
      for (final m in boarded)
        if (ref.watch(cashStatusProvider(ride.id, m.id)).value?.isCash ?? false) m,
    ];
    if (cashRiders.isEmpty) return const SizedBox.shrink();
    return GooraCard(
      key: const Key('cash-after-trip'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tripEndedNote, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          for (final m in cashRiders) _CashRow(ride: ride, member: m, price: view.group!.price),
        ],
      ),
    );
  }
}

class _CashRow extends ConsumerWidget {
  const _CashRow({required this.ride, required this.member, required this.price});

  final Ride ride;
  final Member member;
  final int price;

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
                    label: l10n.cashReceived(price),
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
          amount: price,
          date: ride.date,
        ));
    ref
      ..invalidate(cashStatusProvider(ride.id, member.id))
      ..invalidate(walletControllerProvider);
  }
}
