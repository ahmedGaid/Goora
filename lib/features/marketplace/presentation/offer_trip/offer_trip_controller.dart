import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/now_provider.dart';
import '../../../../core/time/wall_time.dart';
import '../../../commute/data/providers.dart';
import '../../../commute/domain/clock.dart';
import '../../../commute/domain/commute_profile.dart';
import '../../../commute/domain/place.dart';
import '../../../commute/domain/pricing_service.dart';
import '../../../daily/data/providers.dart';
import '../../../daily/domain/trust.dart';
import '../../data/market_seed.dart';
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
    this.from = Area.sheikhZayed,
    this.to = Area.smartVillage,
    this.departure = const Clock.hm(7, 30),
    this.seats = defaultSeats,
    this.contribution = 0,
    this.repeat = Repeat.once,
  });

  static const defaultSeats = 3;

  /// The form at its start: the suggested price for the default seats, on the
  /// given route and time when the driver has a saved commute.
  factory OfferForm.start({Area? from, Area? to, Clock? departure}) =>
      OfferForm(contribution: rangeFor(defaultSeats).suggested).copyWith(from: from, to: to, departure: departure);

  final Area from;
  final Area to;
  final Clock departure;
  final int seats;
  final int contribution;
  final Repeat repeat;

  /// A trip that leaves Smart Village is the way back; any other is the way there.
  Leg get leg => from == Area.smartVillage ? Leg.ret : Leg.going;

  PriceRange get range => rangeFor(seats);

  OfferForm copyWith({Area? from, Area? to, Clock? departure, int? seats, int? contribution, Repeat? repeat}) =>
      OfferForm(
        from: from ?? this.from,
        to: to ?? this.to,
        departure: departure ?? this.departure,
        seats: seats ?? this.seats,
        contribution: contribution ?? this.contribution,
        repeat: repeat ?? this.repeat,
      );

  @override
  bool operator ==(Object other) =>
      other is OfferForm &&
      other.from == from &&
      other.to == to &&
      other.departure == departure &&
      other.seats == seats &&
      other.contribution == contribution &&
      other.repeat == repeat;

  @override
  int get hashCode => Object.hash(from, to, departure.minutes, seats, contribution, repeat);

  OfferDraft toDraft() => OfferDraft(
        leg: leg,
        from: from,
        to: to,
        departure: departure,
        seats: seats,
        contribution: contribution,
        repeat: repeat,
      );

  /// The corridor's trip cost shared across the offered seats (R6).
  static PriceRange rangeFor(int seats) => PricingService.range(MarketSeed.tripCost, seats);
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
      durationMinutes: 40,
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
  final profile = await ref.watch(commuteRepositoryProvider).loadProfile();
  return OfferForm.start(from: profile?.home?.area, to: profile?.work?.area, departure: profile?.departure);
}

/// The form's check, re-read when the form changes.
@riverpod
Future<OfferCheck> offerCheck(Ref ref, OfferForm form) => checkOffer(ref, form, now: ref.read(nowProvider)());

/// One published trip as its driver watches it fill (live, full, departed,
/// done, cancelled).
@riverpod
Future<OfferLive> offerLive(Ref ref, String tripId) =>
    ref.watch(marketplaceRepositoryProvider).live(tripId, now: ref.read(nowProvider)());
