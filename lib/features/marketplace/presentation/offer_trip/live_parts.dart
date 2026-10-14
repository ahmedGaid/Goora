import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/widgets/goora_banner.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../../core/widgets/goora_progress_bar.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/presentation/labels.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';

/// "N of M seats booked" with a progress bar, and "Your car is full!" once
/// every seat has a rider — said in words as well as the bar (VII).
class OfferProgress extends StatelessWidget {
  const OfferProgress({super.key, required this.live});

  final OfferLive live;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seats = live.trip.seats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GooraProgressBar(
          key: const Key('offer-progress'),
          value: seats == 0 ? 0 : live.taken / seats,
          valueLabel: '${live.taken}/$seats',
          label: l10n.seatsBooked(live.taken, seats),
        ),
        if (live.isFull && live.trip.status != OfferStatus.cancelled) ...[
          const SizedBox(height: AppSpacing.md),
          GooraBanner(key: const Key('offer-full'), kind: GooraBannerKind.info, title: l10n.carFull, body: ''),
        ],
      ],
    );
  }
}

/// The riders on a trip: no name and no photo until departure (FR-023, R15) —
/// only "Verified rider", the rating or "New" — then the first name.
class LiveRidersList extends StatelessWidget {
  const LiveRidersList({super.key, required this.riders});

  final List<LiveRider> riders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (riders.isEmpty) {
      return Text(
        l10n.noRidersYet,
        key: const Key('no-riders'),
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      key: const Key('live-riders'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in riders.indexed)
          Padding(
            key: Key('live-rider-$i'),
            padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(GooraIcons.person, size: AppSizes.iconSmall, color: AppColors.greenText),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    r.firstName ?? (r.rider.isWoman ? l10n.verifiedRiderWoman : l10n.verifiedRider),
                    style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  r.rider.rating == null ? l10n.newRider : l10n.ratingStars(r.rider.rating!.toStringAsFixed(1)),
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Tomorrow · 7:30 AM" for a published trip.
String offerWhen(AppLocalizations l10n, OfferedTrip trip, CalendarDate today) =>
    '${l10n.heroWhen(trip.date, today)} · ${l10n.time(trip.departure)}';

/// What the trip's state says in words: on the way, finished, cancelled.
String? offerStateNote(AppLocalizations l10n, OfferStatus status) => switch (status) {
      OfferStatus.departed => l10n.tripDepartedState,
      OfferStatus.done => l10n.tripDoneState,
      OfferStatus.cancelled => l10n.tripCancelledState,
      OfferStatus.grouped => l10n.nowGroup,
      OfferStatus.open || OfferStatus.full => null,
    };
