import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../commute/domain/group.dart';
import '../../../wallet/presentation/share_mark_row.dart';
import '../../domain/check_in.dart';
import 'today_controller.dart';

/// After drop-off, every picked-up passenger gets "استلمت N ج" / "ماستلمتش",
/// then a status (004 v2 FR-012, widened to every passenger by 007 US2: each
/// pays the driver directly, cash or InstaPay). Names are already visible
/// here — only riders who boarded are listed (003 FR-016).
class CashAfterTrip extends ConsumerWidget {
  const CashAfterTrip({super.key, required this.view, required this.leg});

  final TodayView view;
  final LegPlan leg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ride = leg.ride!;
    final group = view.group!;
    final boarded = [
      for (final o in leg.outcomes)
        if (o.outcome == Outcome.pickedUp && o.personId != ride.driverId) group.member(o.personId),
    ].whereType<Member>().toList();
    if (boarded.isEmpty) return const SizedBox.shrink();
    return GooraCard(
      key: const Key('cash-after-trip'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.tripEndedNote, style: AppTypography.bodyStrong.copyWith(color: AppColors.greenText)),
          for (final m in boarded)
            ShareMarkRow(
              rideId: ride.id,
              riderId: m.id,
              driverId: ride.driverId!,
              riderName: m.firstName,
              date: ride.date,
              fallbackAmount: group.price,
            ),
        ],
      ),
    );
  }
}
