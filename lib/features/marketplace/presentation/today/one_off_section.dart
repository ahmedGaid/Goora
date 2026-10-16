import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/routes.dart';
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
import '../../../../core/widgets/goora_status_chip.dart';
import '../../../commute/presentation/labels.dart';
import '../../../daily/data/providers.dart';
import '../../../daily/domain/attendance_rules.dart';
import '../../../daily/presentation/labels.dart';
import '../../../daily/presentation/safety/sos_sheet.dart';
import '../../../daily/presentation/today/today_widgets.dart';
import '../../../onboarding/presentation/session_controller.dart';
import '../../../wallet/data/providers.dart';
import '../../../wallet/domain/cash_mark.dart';
import '../../../wallet/presentation/labels.dart';
import '../../../wallet/presentation/wallet/wallet_controller.dart';
import '../../data/providers.dart';
import '../../domain/booking.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';
import '../../domain/seat_offer.dart';
import '../../domain/trip_request.dart';
import '../empty_seats/empty_seats_controller.dart';
import '../labels.dart';
import '../offer_trip/live_parts.dart';
import '../offer_trip/offer_trip_controller.dart';
import '../post_trip/post_trip_controller.dart';

part 'one_off_section.g.dart';

/// A booked one-off seat with what the card shows of it.
final class OneOffSeat {
  const OneOffSeat(this.booking, this.seat);

  final Booking booking;
  final SeatOffer seat;
}

/// The rider's booked one-off seats on Today. A seat booked on the rider's own
/// group ride is the group card's business, not shown twice (R10). Follows
/// [myBookingsProvider], so a booking made over Today shows on it (T104 F17).
@riverpod
Future<List<OneOffSeat>> oneOffToday(Ref ref) async {
  final market = ref.watch(marketplaceRepositoryProvider);
  final daily = ref.watch(dailyCommuteRepositoryProvider);
  final out = <OneOffSeat>[];
  for (final b in await ref.watch(myBookingsProvider.future)) {
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
    final posted = ref.watch(myPostedRequestsProvider).value ?? const <TripRequest>[];
    if (trips.isEmpty && posted.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('one-off-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.oneOffTrips),
        for (final r in posted) ...[
          _PostedCard(request: r),
          const SizedBox(height: AppSpacing.gap),
        ],
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

// ----------------------------------------------------------- driver side

/// The driver's offered trips in the coming week, each with its live state.
/// A group's legs are the group card's business; only `of-` trips show here.
@riverpod
Future<List<OfferLive>> driverOffers(Ref ref) async {
  final now = ref.watch(nowProvider)();
  final market = ref.watch(marketplaceRepositoryProvider);
  final ids = <String>{};
  for (var i = 0; i <= 7; i++) {
    for (final t in (await market.driverDay(now.date.addDays(i))).trips) {
      // A group ride id is `<groupId>:<date>:<leg>`; an offer's has no colon.
      if (!t.id.contains(':')) ids.add(t.id);
    }
  }
  return [for (final id in ids) await market.live(id, now: now)];
}

/// Cash the driver marked on an offered trip (`offer:<id>`), by rider.
@riverpod
Future<List<CashMark>> offerCashMarks(Ref ref, String rideId) => ref.watch(walletRepositoryProvider).cashMarks(rideId);

/// Re-reads everything a change to the offer [id] touches.
void refreshDriverOffers(WidgetRef ref, String id) {
  ref
    ..invalidate(offerLiveProvider(id))
    ..invalidate(driverOffersProvider)
    ..invalidate(walletControllerProvider);
}

/// Cancel trip with its one sentence of consequence: every rider gets back
/// everything they paid (SC-005).
Future<void> cancelOfferWithConfirm(BuildContext context, WidgetRef ref, String id) async {
  final l10n = AppLocalizations.of(context);
  final sure = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.cancelTripConfirm),
      actions: [
        TextButton(
          key: const Key('keep-trip'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.keepTrip),
        ),
        TextButton(
          key: const Key('confirm-cancel-trip'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.cancelTrip),
        ),
      ],
    ),
  );
  if (sure != true) return;
  await ref.read(marketplaceRepositoryProvider).cancelOffer(id, now: ref.read(nowProvider)());
  refreshDriverOffers(ref, id);
}

/// "One-off trips" on driver Today: the trips this driver offered.
class DriverOffersSection extends ConsumerWidget {
  const DriverOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offers = ref.watch(driverOffersProvider).value ?? const <OfferLive>[];
    if (offers.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('driver-offers'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.oneOffTrips),
        for (final live in offers) ...[
          _OfferCard(live: live),
          const SizedBox(height: AppSpacing.gap),
        ],
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.live});

  final OfferLive live;

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final trip = live.trip;
    final name = ref.read(sessionControllerProvider).profile?.firstName ?? '';
    // Areas and my first name only; the token names no rider (FR-031).
    final text = l10n.shareMessage(
      name,
      '',
      l10n.area(trip.from),
      l10n.area(trip.to),
      l10n.time(trip.departure.shift(trip.durationMinutes)),
      '${Env.shareBaseUrl}/t/${trip.id}',
    );
    await ref.read(tripSharerProvider).share(text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(nowProvider)().date;
    final trip = live.trip;
    final note = offerStateNote(l10n, trip.status);
    final open = trip.status == OfferStatus.open || trip.status == OfferStatus.full;
    final cashRiders = trip.status == OfferStatus.done
        ? [for (final r in live.riders) if (r.paidBy == PaidBy.cash && r.riderId != null) r]
        : const <LiveRider>[];
    return GooraCard(
      key: Key('driver-offer-${trip.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.routeLine(l10n.area(trip.from), l10n.area(trip.to)),
            style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
          ),
          Text(offerWhen(l10n, trip, today), style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          if (note != null) ...[
            Text(note, style: AppTypography.bodyStrong.copyWith(color: AppColors.textBody)),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            OfferProgress(live: live),
            const SizedBox(height: AppSpacing.md),
          ],
          if (trip.status != OfferStatus.cancelled) LiveRidersList(riders: live.riders),
          if (open) ...[
            const SizedBox(height: AppSpacing.md),
            GooraGhostButton(
              key: Key('cancel-trip-${trip.id}'),
              label: l10n.cancelTrip,
              danger: true,
              onPressed: () => cancelOfferWithConfirm(context, ref, trip.id),
            ),
          ],
          // From departure to the end, Share and SOS are one tap away (Constitution V).
          if (trip.status == OfferStatus.departed) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GooraGhostButton(
                    key: Key('offer-share-${trip.id}'),
                    label: l10n.shareTrip,
                    icon: GooraIcons.share,
                    onPressed: () => _share(context, ref),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GooraGhostButton(
                    key: Key('offer-sos-${trip.id}'),
                    label: l10n.sos,
                    icon: GooraIcons.sos,
                    danger: true,
                    onPressed: () => showSosSheet(context, rideId: Booking.offerRideId(trip.id)),
                  ),
                ),
              ],
            ),
          ],
          for (final r in cashRiders) _OfferCashRow(trip: trip, rider: r),
        ],
      ),
    );
  }
}

/// A cash rider after an offered trip: "Received N EGP cash" or "Didn't pay".
/// The mark is stored against `offer:<id>`, like a group trip's (FR-029).
class _OfferCashRow extends ConsumerWidget {
  const _OfferCashRow({required this.trip, required this.rider});

  final OfferedTrip trip;
  final LiveRider rider;

  String get _rideId => Booking.offerRideId(trip.id);

  int get _amount => rider.price?.cash ?? rider.price?.contribution ?? trip.contribution;

  Future<void> _record(WidgetRef ref, CashOutcome outcome) async {
    await ref.read(walletRepositoryProvider).markCash(CashMark(
          rideId: _rideId,
          riderId: rider.riderId!,
          driverId: trip.driverId,
          outcome: outcome,
          amount: _amount,
          date: trip.date,
        ));
    ref
      ..invalidate(offerCashMarksProvider(_rideId))
      ..invalidate(walletControllerProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = rider.riderId!;
    final marks = ref.watch(offerCashMarksProvider(_rideId)).value ?? const <CashMark>[];
    final outcome = marks.where((m) => m.riderId == id).firstOrNull?.outcome;
    return Padding(
      key: Key('cash-$id'),
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(rider.firstName ?? '', style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          if (outcome != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: outcome == CashOutcome.received
                  ? GooraStatusChip(status: GooraStatus.covered, label: l10n.cashMarkedReceived)
                  : GooraStatusChip(status: GooraStatus.off, label: l10n.cashMarkedUnpaid),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GooraGhostButton(
                  key: Key('cash-received-$id'),
                  label: l10n.cashReceived(_amount),
                  onPressed: () => _record(ref, CashOutcome.received),
                ),
                const SizedBox(height: AppSpacing.sm),
                GooraGhostButton(
                  key: Key('cash-unpaid-$id'),
                  label: l10n.didNotPay,
                  onPressed: () => _record(ref, CashOutcome.didNotPay),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A trip the rider posted that no driver has taken yet: tap to open it.
class _PostedCard extends ConsumerWidget {
  const _PostedCard({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(nowProvider)().date;
    return GooraCard(
      key: Key('posted-${request.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.routeLine(l10n.area(request.from), l10n.area(request.to)),
            style: AppTypography.bodyStrong.copyWith(color: AppColors.textPrimary),
          ),
          Text(
            '${l10n.heroWhen(request.date, today)} · ${l10n.time(request.departure)}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.waitingDriver, style: AppTypography.body.copyWith(color: AppColors.textBody)),
          const SizedBox(height: AppSpacing.md),
          GooraGhostButton(
            key: Key('open-posted-${request.id}'),
            label: l10n.seeYourRequest,
            onPressed: () => context.push('${Routes.postTrip}?id=${request.id}'),
          ),
        ],
      ),
    );
  }
}
