import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../../core/time/wall_time.dart';
import '../../../commute/data/providers.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/corridor.dart';
import '../../../commute/domain/place.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../daily/data/providers.dart';
import '../../../daily/domain/trust.dart';
import '../../data/providers.dart';
import '../../domain/driver_day_rules.dart';
import '../../domain/market_day.dart';
import '../../domain/marketplace_repository.dart';
import '../../domain/offered_trip.dart';

part 'offer_trip_controller.g.dart';

/// What a driver has filled in on Offer a trip (C). The price is never typed:
/// it moves in 2 EGP steps inside `PricingService.range` (FR-015, FR-022).
final class OfferForm {
  const OfferForm({
    required this.corridor,
    required this.from,
    required this.to,
    this.home,
    this.work,
    this.departure = const Clock.hm(7, 30),
    this.seats = defaultSeats,
    this.contribution = 0,
    this.repeat = Repeat.once,
  });

  static const defaultSeats = 3;

  /// The form at its start: the suggested price for the default seats, on the
  /// driver's saved route and time, else the corridor's default route (006 R4).
  factory OfferForm.start(Corridor corridor, {Area? home, Area? work, Clock? departure}) => OfferForm(
        corridor: corridor,
        from: home ?? corridor.defaultFrom,
        to: work ?? corridor.defaultTo,
        home: home,
        work: work,
        contribution: PricingService.range(corridor.tripCost, defaultSeats).suggested,
      ).copyWith(departure: departure);

  /// The active corridor: its trip cost prices the seats.
  final Corridor corridor;
  final Area from;
  final Area to;

  /// The driver's saved home and work areas, which decide the leg (R5).
  final Area? home;
  final Area? work;
  final Clock departure;
  final int seats;
  final int contribution;
  final Repeat repeat;

  /// Leaving home is the way there, coming home the way back (research R5).
  Leg get leg => corridor.legOf(from, to, home: home, work: work);

  PriceRange get range => rangeFor(seats);

  /// The corridor's trip cost shared across [seats] offered seats.
  PriceRange rangeFor(int seats) => PricingService.range(corridor.tripCost, seats);

  OfferForm copyWith({Area? from, Area? to, Clock? departure, int? seats, int? contribution, Repeat? repeat}) =>
      OfferForm(
        corridor: corridor,
        from: from ?? this.from,
        to: to ?? this.to,
        home: home,
        work: work,
        departure: departure ?? this.departure,
        seats: seats ?? this.seats,
        contribution: contribution ?? this.contribution,
        repeat: repeat ?? this.repeat,
      );

  @override
  bool operator ==(Object other) =>
      other is OfferForm &&
      identical(other.corridor, corridor) &&
      other.from == from &&
      other.to == to &&
      other.home == home &&
      other.work == work &&
      other.departure == departure &&
      other.seats == seats &&
      other.contribution == contribution &&
      other.repeat == repeat;

  @override
  int get hashCode => Object.hash(corridor.id, from, to, home, work, departure.minutes, seats, contribution, repeat);

  OfferDraft toDraft() => OfferDraft(
        leg: leg,
        from: from,
        to: to,
        departure: departure,
        seats: seats,
        contribution: contribution,
        repeat: repeat,
      );
}

/// Why Publish is on or off, from the repository's own rules (FR-014, FR-019).
final class OfferCheck {
  const OfferCheck({required this.missing, required this.fit, required this.trips});

  /// Documents not verified yet; each is a chip that opens Trust.
  final List<VerificationKind> missing;
  final TripFit fit;

  /// The driver's trips that day, to name the one a join lands on.
  final List<DayTrip> trips;

  bool get canPublish => missing.isEmpty && fit.kind == TripFitKind.create;

  /// "This joins your trip at {time}" needs the time of the trip it lands on.
  Clock? get joinTime {
    final id = fit.tripId;
    final trip = trips.where((t) => t.id == id).firstOrNull;
    return trip == null ? null : Clock(trip.departure);
  }
}

/// Reads the same facts `publish` will use, so the screen can say why a
/// button is off before the tap instead of after.
Future<OfferCheck> checkOffer(Ref ref, OfferForm form, {required WallTime now}) async {
  final profile = await ref.read(trustRepositoryProvider).profile();
  final missing = [
    for (final item in profile.items)
      if (publishChecks.contains(item.kind) && item.status != VerificationStatus.verified) item.kind,
  ];
  final market = ref.read(marketplaceRepositoryProvider);
  final day = await market.driverDay(MarketDay.nextWorkday(form.departure, now));
  final fit = DriverDayRules.fit(
    day.trips,
    Candidate(
      leg: form.leg,
      from: form.from,
      to: form.to,
      departure: form.departure.minutes,
      durationMinutes: form.corridor.tripMinutes(form.from, form.to),
      daily: form.repeat == Repeat.daily,
      leadsGroup: day.leadsGroup,
    ),
  );
  return OfferCheck(missing: missing, fit: fit, trips: day.trips);
}

/// Where the form starts: the driver's saved commute, home → work at their
/// time (T104 F22), like Post your trip's `postStart`.
@riverpod
Future<OfferForm> offerStart(Ref ref) async {
  final corridor = ref.watch(activeCorridorProvider);
  final profile = await ref.watch(commuteRepositoryProvider).loadProfile();
  return OfferForm.start(corridor, home: profile?.home?.area, work: profile?.work?.area, departure: profile?.departure);
}

/// The form's check, re-read when the form changes.
@riverpod
Future<OfferCheck> offerCheck(Ref ref, OfferForm form) => checkOffer(ref, form, now: ref.read(nowProvider)());

/// One published trip as its driver watches it fill (live, full, departed,
/// done, cancelled).
@riverpod
Future<OfferLive> offerLive(Ref ref, String tripId) =>
    ref.watch(marketplaceRepositoryProvider).live(tripId, now: ref.read(nowProvider)());
