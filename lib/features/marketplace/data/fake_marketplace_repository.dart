import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/data/group_catalog.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/notice.dart';
import '../../daily/domain/ride.dart';
import '../../daily/domain/trust_repository.dart';
import '../../wallet/domain/done_one_off.dart';
import '../../wallet/domain/wallet_repository.dart';
import '../domain/booking.dart';
import '../domain/driver_day.dart';
import '../domain/driver_day_rules.dart';
import '../domain/marketplace_repository.dart';
import '../domain/offered_trip.dart';
import '../domain/seat_math.dart';
import '../domain/seat_offer.dart';
import '../domain/trip_request.dart';
import 'market_seed.dart';

/// The seat marketplace on fake data over shared_preferences (005
/// data-model.md "Fake storage keys"). Seeded offers and requests come from
/// [MarketSeed] and are overlaid with whatever was stored for the same id, so
/// the corridor is never empty and a status change survives a restart.
///
/// Phase 4 builds the data layer: [driverDay] (research R5), [doneOneOffs]
/// (the wallet's seam, T038) and [clear]. The story methods throw
/// [UnimplementedError] until the phase that builds their story (tasks.md:
/// US1 Phase 5, US2 Phase 6, US3 Phase 7, US4 Phase 8, US6 Phase 10).
final class FakeMarketplaceRepository implements MarketplaceRepository {
  FakeMarketplaceRepository(
    this._prefs, {
    required this._catalog,
    required this._daily,
    required this.notices,
    required this.ledger,
    required this.wallet,
    required this.trust,
    required this._now,
  });

  static const offersKey = 'market.offers';
  static const requestsKey = 'market.requests';
  static const bookingsKey = 'market.bookings';

  /// Next index into the fake rider / driver pools for the demo actions.
  static const seedCursorKey = 'market.seedCursor';

  /// Every key the marketplace owns, groups and added members included.
  static const keyPrefix = 'market.';

  final SharedPreferences _prefs;
  final GroupCatalog _catalog;
  final DailyCommuteRepository _daily;
  final Now _now;

  /// The seams the story methods use from Phase 5 on: notices and reliability
  /// into 003, money into 004's ledger, the payment gate, the verification
  /// check. Public so a method added later needs no constructor change.
  ///
  /// The wallet comes as a function: the wallet reads this repository's
  /// finished trips, so neither may depend on the other while it is built.
  final NoticeSink notices;
  final SeatLedger Function() ledger;
  final WalletRepository Function() wallet;
  final TrustRepository trust;

  /// Settings → "Reset demo data": every `market.*` key, including the groups
  /// and members the catalog stores.
  static Future<void> clearAll(SharedPreferences prefs) async {
    for (final key in prefs.getKeys().where((k) => k.startsWith(keyPrefix)).toList()) {
      await prefs.remove(key);
    }
  }

  Future<void> clear() => clearAll(_prefs);

  // --------------------------------------------------------------- storage

  /// Seeded offers with their stored overlay, then the stored ones that are
  /// not seeded (the person's own and those made by accepting).
  List<OfferedTrip> _offers() {
    final stored = _read(offersKey, OfferedTrip.fromJson);
    final byId = {for (final o in stored) o.id: o};
    return [
      for (final o in MarketSeed.offers(_now())) byId.remove(o.id) ?? o,
      ...byId.values,
    ];
  }

  List<TripRequest> _requests() {
    final stored = _read(requestsKey, TripRequest.fromJson);
    final byId = {for (final r in stored) r.id: r};
    return [
      for (final r in MarketSeed.requests(_now())) byId.remove(r.id) ?? r,
      ...byId.values,
    ];
  }

  List<Booking> _bookings() => _read(bookingsKey, Booking.fromJson);

  List<T> _read<T>(String key, T Function(Map<String, Object?>) fromJson) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return [for (final e in jsonDecode(raw) as List) fromJson((e as Map).cast<String, Object?>())];
  }

  /// A booking that holds a seat: not cancelled, reclaimed or refunded.
  static bool _holdsSeat(Booking b) => b.status == BookingStatus.booked || b.status == BookingStatus.done;

  // ------------------------------------------------------------ driver day

  /// R5: the group legs the person actually drives, plus their offered trips
  /// that count. The group legs come from the schedule's *actual* driver, so
  /// a leg a backup covers, or nobody does, is left out.
  @override
  Future<DriverDay> driverDay(CalendarDate date) async {
    final me = _daily.meId;
    final now = _now();
    final bookings = [for (final b in _bookings()) if (_holdsSeat(b)) b];
    final trips = <DayTrip>[];
    var leadsGroup = false;

    final group = await _daily.myGroup();
    if (group != null) {
      leadsGroup = group.member(me)?.role == MemberRole.driver;
      final day = (await _daily.schedule(date, date)).where((d) => d.date == date).firstOrNull;
      for (final leg in Leg.values) {
        if (day?.assignment(leg)?.actual != me) continue;
        final ride = await _daily.ride(date, leg);
        if (ride == null) continue;
        final holds = [
          for (final b in bookings)
            if (b.source == BookingSource.groupSeat(group.id) && b.date == date && b.leg == leg) b.holdAt(now),
        ];
        final free = SeatMath.ownGroupLeg(ride, riderSeats: group.riderSeats, bookings: holds);
        final going = leg == Leg.going;
        trips.add(DayTrip(
          id: Ride.idFor(group.id, date, leg),
          leg: leg,
          from: going ? group.origin : group.destination,
          to: going ? group.destination : group.origin,
          departure: group.timeFor(leg).minutes,
          durationMinutes: group.tripMinutes,
          seats: group.riderSeats,
          taken: group.riderSeats - free,
        ));
      }
    }

    for (final o in _offers()) {
      if (o.driverId != me || o.date != date) continue;
      // A grouped daily offer is already the group's leg above.
      if (o.status == OfferStatus.grouped) continue;
      // Cancelled with no bookings frees the trip; with riders it still counts
      // and is full, so a request can't join a trip that isn't running.
      if (o.status == OfferStatus.cancelled && !o.cancelledWithRiders) continue;
      final taken = o.status == OfferStatus.cancelled
          ? o.seats
          : bookings.where((b) => b.source == BookingSource.offer(o.id)).length;
      trips.add(DayTrip(
        id: o.id,
        leg: o.leg,
        from: o.from,
        to: o.to,
        departure: o.departure.minutes,
        durationMinutes: o.durationMinutes,
        seats: o.seats,
        taken: taken > o.seats ? o.seats : taken,
      ));
    }

    trips.sort((a, b) {
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return DriverDay(date: date, trips: trips, leadsGroup: leadsGroup);
  }

  // ----------------------------------------------------------- wallet seam

  /// Every finished one-off seat: booked and past the trip's end, or already
  /// marked done. The wallet filters by person and role (research R9).
  @override
  Future<List<DoneOneOff>> doneOneOffs() async {
    final now = _now();
    final done = <DoneOneOff>[];
    for (final b in _bookings()) {
      final isDone = b.status == BookingStatus.done;
      if (!isDone && b.status != BookingStatus.booked) continue;
      final trip = _tripOf(b);
      if (trip == null || (!isDone && now.isBefore(trip.end))) continue;
      done.add(DoneOneOff(
        rideId: b.rideId,
        date: b.date,
        leg: b.leg,
        paidBy: b.paidBy,
        contribution: b.price.contribution,
        tripCost: trip.tripCost,
        riderSeats: trip.riderSeats,
        riderId: b.riderId,
        driverId: trip.driverId,
      ));
    }
    return done;
  }

  /// What a booking rides on: an offered trip, a group's leg, or the trip an
  /// accepted request was seated in.
  ({String driverId, int tripCost, int riderSeats, WallTime end})? _tripOf(Booking b) {
    switch (b.source.kind) {
      case BookingSourceKind.offer:
        return _offerTrip(b.source.id);
      case BookingSourceKind.groupSeat:
        return _groupTrip(b.source.id, b);
      case BookingSourceKind.request:
        final tripId = _requests().where((r) => r.id == b.source.id).firstOrNull?.tripId;
        if (tripId == null) return null;
        // A group ride id is `<groupId>:<date>:<leg>`; an offer's is its id.
        return _offerTrip(tripId) ?? _groupTrip(tripId.split(':').first, b);
    }
  }

  ({String driverId, int tripCost, int riderSeats, WallTime end})? _offerTrip(String tripId) {
    final o = _offers().where((o) => o.id == tripId).firstOrNull;
    if (o == null) return null;
    return (
      driverId: o.driverId,
      tripCost: o.tripCost,
      riderSeats: o.riderSeats,
      end: WallTime(o.date, o.departure).plusMinutes(o.durationMinutes),
    );
  }

  ({String driverId, int tripCost, int riderSeats, WallTime end})? _groupTrip(String groupId, Booking b) {
    final g = _catalog.byId(groupId);
    if (g == null) return null;
    return (
      driverId: g.driverFor(b.leg)?.id ?? '',
      tripCost: g.tripCost,
      riderSeats: g.riderSeats,
      end: WallTime(b.date, g.endFor(b.leg)),
    );
  }

  // --------------------------------------------- stories (later phases)

  @override
  Future<List<SeatOffer>> seatOffers(Leg leg, {required WallTime now}) => throw UnimplementedError('Phase 5 (US1)');

  @override
  Future<BookResult> book(SeatOffer offer, {required WallTime now}) => throw UnimplementedError('Phase 5 (US1)');

  @override
  Future<CancelResult> cancelBooking(String bookingId, {required WallTime now}) =>
      throw UnimplementedError('Phase 5 (US1)');

  @override
  Future<List<Booking>> myBookings({required WallTime now}) => throw UnimplementedError('Phase 5 (US1)');

  @override
  Future<PostResult> post(TripDraft draft, {required WallTime now}) => throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<void> cancelRequest(String requestId) => throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<TripRequest?> request(String requestId, {required WallTime now}) =>
      throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<int> driversOnRoute(TripDraft draft) => throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<PublishResult> publish(OfferDraft draft, {required WallTime now}) =>
      throw UnimplementedError('Phase 6 (US2)');

  @override
  Future<OfferedTrip?> offer(String tripId, {required WallTime now}) => throw UnimplementedError('Phase 6 (US2)');

  @override
  Future<OfferLive> live(String tripId, {required WallTime now}) => throw UnimplementedError('Phase 6 (US2)');

  @override
  Future<void> cancelOffer(String tripId, {required WallTime now}) => throw UnimplementedError('Phase 6 (US2)');

  @override
  Future<List<RequestCard>> requestsForMe({Area? leavingFrom, required PartOfDay part, required WallTime now}) =>
      throw UnimplementedError('Phase 8 (US4)');

  @override
  Future<AcceptResult> accept(String requestId, {required WallTime now}) => throw UnimplementedError('Phase 8 (US4)');

  @override
  Future<ReclaimResult> reclaim(String bookingId, {required WallTime now}) =>
      throw UnimplementedError('Phase 10 (US6)');

  @override
  Future<DemoResult> demoDriverAccepts({required WallTime now}) => throw UnimplementedError('its story (debug demo, FR-028)');

  @override
  Future<DemoResult> demoRiderBooks({required WallTime now}) => throw UnimplementedError('its story (debug demo, FR-028)');

  @override
  Future<DemoResult> demoSubscriberTakes({required WallTime now}) => throw UnimplementedError('its story (debug demo, FR-028)');
}
