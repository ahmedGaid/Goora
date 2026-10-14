import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/env.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/time/now_provider.dart';
import '../../../../core/widgets/goora_avatar.dart';
import '../../../../core/widgets/goora_card.dart';
import '../../../../core/widgets/goora_ghost_button.dart';
import '../../../../core/widgets/goora_icons.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/data/providers.dart';
import '../../../daily/domain/attendance_rules.dart';
import '../../../daily/presentation/safety/sos_sheet.dart';
import '../../../daily/presentation/today/today_widgets.dart';
import '../../../wallet/presentation/labels.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../data/providers.dart';
import '../../domain/booking.dart';
import '../../domain/seat_offer.dart';
import '../empty_seats/empty_seats_controller.dart';
import '../labels.dart';

part 'one_off_section.g.dart';

/// A booked one-off seat with what the card shows of it.
final class OneOffSeat {
  const OneOffSeat(this.booking, this.seat);

  final Booking booking;
  final SeatOffer seat;
}

/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10).
@riverpod
Future<List<OneOffSeat>> oneOffToday(Ref ref) async {
  final now = ref.watch(nowProvider)();
  final market = ref.watch(marketplaceRepositoryProvider);
  final daily = ref.watch(dailyCommuteRepositoryProvider);
  final out = <OneOffSeat>[];
  for (final b in await market.myBookings(now: now)) {
    final mine = await daily.ride(b.date, b.leg);
    if (mine != null && mine.id == b.rideId && mine.carries(daily.meId)) continue;
    final seat = await market.seatOf(b);
    if (seat != null) out.add(OneOffSeat(b, seat));
  }
  return out;
}

/// "One-off trips": each booked seat with the driver, pickup, price line, the
/// cancel rule, and Share and SOS one tap away (Constitution V).
class OneOffSection extends ConsumerWidget {
  const OneOffSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(oneOffTodayProvider).value ?? const <OneOffSeat>[];
    if (trips.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('one-off-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.oneOffTrips),
        for (final t in trips) ...[
          _OneOffCard(trip: t),
          const SizedBox(height: AppSpacing.gap),
        ],
      ],
    );
  }
}

class _OneOffCard extends ConsumerWidget {
  const _OneOffCard({required this.trip});

  final OneOffSeat trip;

  Future<void> _cancel(WidgetRef ref) async {
    await ref.read(marketplaceRepositoryProvider).cancelBooking(trip.booking.id, now: ref.read(nowProvider)());
    ref
      ..invalidate(oneOffTodayProvider)
      ..invalidate(myBookingsProvider)
      ..invalidate(seatOffersProvider)
      ..invalidate(walletControllerProvider);
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final seat = trip.seat;
    final from = seat.from;
    final to = seat.to;
    if (from == null || to == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.shareNoTrip)));
      return;
    }
    // Areas and the driver's first name only; the token names no person (FR-031).
    final text = l10n.shareMessage(
      seat.driver.firstName,
      '',
      l10n.area(from),
      l10n.area(to),
      l10n.time(seat.arrival ?? seat.departure),
      '${Env.shareBaseUrl}/t/${trip.booking.id}',
    );
    await ref.read(tripSharerProvider).share(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(nowProvider)();
    final seat = trip.seat;
    final late = AttendanceRules.isLate(seat.date, now);
    return GooraCard(
      key: Key('one-off-${trip.booking.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GooraAvatar(initials: seat.driver.initials),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(seat.driver.firstName, style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.seatWhen(seat, now), style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          Text(l10n.seatPickup(seat), style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.priceLine(trip.booking.price), style: AppTypography.body.copyWith(color: AppColors.textBody)),
          const SizedBox(height: AppSpacing.md),
          GooraGhostButton(
            key: Key('cancel-booking-${trip.booking.id}'),
            label: l10n.cancelBooking,
            onPressed: () => _cancel(ref),
          ),
          const SizedBox(height: AppSpacing.xs),
          Caption(late ? l10n.lateBookingNote : l10n.cancelFreeNote),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GooraGhostButton(
                  key: Key('one-off-share-${trip.booking.id}'),
                  label: l10n.shareTrip,
                  icon: GooraIcons.share,
                  onPressed: () => _share(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: GooraGhostButton(
                  key: Key('one-off-sos-${trip.booking.id}'),
                  label: l10n.sos,
                  icon: GooraIcons.sos,
                  danger: true,
                  onPressed: () => showSosSheet(context, rideId: trip.booking.rideId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
