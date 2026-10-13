import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../commute/domain/group.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/payment_method.dart';
import '../../../wallet/domain/seat_price.dart';
import '../../domain/check_in.dart';
import 'cash_received_row.dart';
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
    final group = view.group!;
    final price =
        SeatPrice.of(group.price, tripCost: group.tripCost, riderSeats: group.riderSeats, mode: PricingMode.cash);
    return GooraCard(
      key: const Key('cash-after-trip'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tripEndedNote, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          for (final m in cashRiders) CashReceivedRow(ride: ride, member: m, price: price),
        ],
      ),
    );
  }
}
