import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/now_provider.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/data/group_catalog.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/commute_repository.dart';
import '../../commute/domain/geo.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../commute/domain/pricing_service.dart';
import '../../daily/domain/attendance_rules.dart';
import '../../daily/domain/charge.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/notice.dart';
import '../../daily/domain/privacy.dart';
import '../../daily/domain/ride.dart';
import '../../daily/domain/trust.dart';
import '../../daily/domain/trust_repository.dart';
import '../../wallet/domain/done_one_off.dart';
import '../../wallet/domain/payment_method.dart';
import '../../wallet/domain/payment_provider.dart';
import '../../wallet/domain/seat_price.dart';
import '../../wallet/domain/wallet_repository.dart';
import '../domain/anonymous_rider.dart';
import '../domain/booking.dart';
import '../domain/booking_gate.dart';
import '../domain/booking_refund.dart';
import '../domain/driver_day.dart';
import '../domain/driver_day_rules.dart';
import '../domain/market_day.dart';
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
/// Phase 4 built the data layer: [driverDay] (research R5), [doneOneOffs]
/// (the wallet's seam, T038) and [clear]. Phase 5 adds the rider's side of
/// US1 (Empty seats). The other story methods throw [UnimplementedError]
/// until the phase that builds their story (tasks.md: US2 Phase 6, US3
/// Phase 7, US4 Phase 8, US6 Phase 10).
final class FakeMarketplaceRepository implements MarketplaceRepository {
  FakeMarketplaceRepository(
    this._prefs, {
    required this._catalog,
    required this._daily,
    required this._commute,
    required this.notices,
    required this.ledger,
    required this.wallet,
    required this.trust,
    required this._now,
  });

  static const offersKey = 'market.offers';
  static const requestsKey = 'market.requests';
  static const bookingsKey = 'market.bookings';

  /// Late-cancel charges owed to drivers (a 003-style `Charge`).
  static const chargesKey = 'market.charges';

  /// Next index into the fake rider / driver pools for the demo actions.
  static const seedCursorKey = 'market.seedCursor';

  /// Every key the marketplace owns, groups and added members included.
  static const keyPrefix = 'market.';

  /// Synchronous check for the router's first location (R12): the person has
  /// a live one-off booking, an open offer or an open request.
  static bool hasOneOff(SharedPreferences prefs, String meId) {
    bool any(String key, String who, Set<String> live) {
      final raw = prefs.getString(key);
      if (raw == null) return false;
      try {
        return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>().any(
              (m) => m[who] == meId && live.contains(m['status']),
            );
      } on Object {
        return false;
      }
    }

    return any(bookingsKey, 'riderId', {BookingStatus.booked.name}) ||
        any(offersKey, 'driverId', {OfferStatus.open.name, OfferStatus.full.name}) ||
        any(requestsKey, 'riderId', {RequestStatus.posted.name});
  }

  final SharedPreferences _prefs;
  final GroupCatalog _catalog;
  final DailyCommuteRepository _daily;
  final CommuteRepository _commute;
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
  _TripInfo? _tripOf(Booking b) {
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

  _TripInfo? _offerTrip(String tripId) {
    final o = _offers().where((o) => o.id == tripId).firstOrNull;
    if (o == null) return null;
    return (
      driverId: o.driverId,
      tripCost: o.tripCost,
      riderSeats: o.riderSeats,
      start: WallTime(o.date, o.departure),
      end: WallTime(o.date, o.departure).plusMinutes(o.durationMinutes),
    );
  }

  _TripInfo? _groupTrip(String groupId, Booking b) {
    final g = _catalog.byId(groupId);
    if (g == null) return null;
    return (
      driverId: g.driverFor(b.leg)?.id ?? '',
      tripCost: g.tripCost,
      riderSeats: g.riderSeats,
      start: WallTime(b.date, g.timeFor(b.leg)),
      end: WallTime(b.date, g.endFor(b.leg)),
    );
  }

  // ------------------------------------------------------ A: Empty seats

  /// The signed-in rider as the marketplace prices and filters them.
  Future<_Rider> _rider(WallTime now) async {
    final me = _daily.meId;
    final profile = await trust.profile();
    final w = wallet();
    final data = await w.getWallet(me);
    final plan = await w.getPlan(me);
    final covered = plan != null && plan.coversDate(now.date);
    final mode = PricingMode.of(
      method: data.method,
      plan: plan,
      today: now.date,
      cashAvailable: data.cashTrial?.available ?? false,
    );
    return _Rider(
      profile: profile,
      mode: mode,
      hasArrangement: data.method != null || covered,
      balance: data.balance,
      // A paid-up plan or a company one: may take a seat a one-off booker could still lose (US6).
      subscriber: mode == PricingMode.subscribed || mode == PricingMode.company,
    );
  }

  /// The rider's route for [leg] — their group's, else their saved commute.
  /// Null when nothing says where they go.
  Future<({Area from, Area to, GeoPoint? home})?> _route(Leg leg) async {
    final group = await _daily.myGroup();
    final profile = await _commute.loadProfile();
    final Area? home = group?.origin ?? profile?.home?.area;
    final Area? work = group?.destination ?? profile?.work?.area;
    if (home == null || work == null) return null;
    final going = leg == Leg.going;
    return (from: going ? home : work, to: going ? work : home, home: profile?.home?.point);
  }

  /// A leg-date the person already rides: a booked seat on it, their own
  /// group's ride, or one they drive. Nothing else is bookable on it.
  Future<bool> _ridesLeg(CalendarDate date, Leg leg, List<Booking> mine) async {
    if (mine.any((b) => b.date == date && b.leg == leg && _holdsSeat(b))) return true;
    final me = _daily.meId;
    final ride = await _daily.ride(date, leg);
    // A ride nobody drives (no cover) carries no one; a leg the rider cancelled
    // is not one they ride either — its seat is free to book elsewhere. Their
    // own driving absence is not that.
    if (ride == null || !(ride.driverId == me || (ride.driverId != null && ride.passengers.any((p) => p.memberId == me)))) {
      return false;
    }
    final away = await _daily.absences(date, date);
    return !away.any((a) => a.personId == me && a.leg == leg && !a.driving);
  }

  /// Holds on [source]'s leg-date, as seat math needs them.
  List<SeatHold> _holds(BookingSource source, CalendarDate date, Leg leg, WallTime now, List<Booking> all) => [
    for (final b in all)
      if (_holdsSeat(b) && b.source == source && b.date == date && b.leg == leg) b.holdAt(now),
  ];

  static SeatDriver _driverOf(Member m) =>
      SeatDriver(id: m.id, firstName: m.firstName, initials: m.initials, rating: m.rating, isWoman: m.isWoman);

  @override
  Future<List<SeatOffer>> seatOffers(Leg leg, {required WallTime now}) async {
    final route = await _route(leg);
    if (route == null) return [];
    final me = _daily.meId;
    final rider = await _rider(now);
    final privacy = rider.profile.privacy;
    final facts = rider.profile.facts;
    final all = _bookings();
    final mine = [for (final b in all) if (b.riderId == me) b];
    final myGroup = await _daily.myGroup();
    final riding = <CalendarDate, bool>{};
    Future<bool> ridesOn(CalendarDate d) async => riding[d] ??= await _ridesLeg(d, leg, mine);

    final seats = <SeatOffer>[];

    for (final o in _offers()) {
      if (o.leg != leg || o.driverId == me || o.from != route.from || o.to != route.to) continue;
      if (o.status != OfferStatus.open && o.status != OfferStatus.full) continue;
      if (MarketDay.isExpired(o.date, o.departure, now)) continue;
      final driver = MarketSeed.driverById(o.driverId) ?? _unknownDriver(o.driverId);
      if (!PrivacyRules.accepts(privacy, facts, PersonFacts(isWoman: driver.isWoman))) continue;
      if (await ridesOn(o.date)) continue;
      final source = BookingSource.offer(o.id);
      final free = SeatMath.offeredTrip(
        seats: o.seats,
        bookings: _holds(source, o.date, o.leg, now, all),
        subscriberView: rider.subscriber,
      );
      if (free <= 0) continue;
      seats.add(SeatOffer(
        source: source,
        driver: driver,
        pickup: o.pickup,
        date: o.date,
        leg: o.leg,
        departure: o.departure,
        freeSeats: free,
        price: SeatPrice.of(o.contribution, tripCost: o.tripCost, riderSeats: o.riderSeats, mode: rider.mode),
      ));
    }

    final going = leg == Leg.going;
    for (final g in _catalog.all()) {
      if (g.id == myGroup?.id) continue;
      if ((going ? g.origin : g.destination) != route.from || (going ? g.destination : g.origin) != route.to) continue;
      if (g.detourMinutes >= _maxDetour) continue;
      final driver = g.driverFor(leg);
      if (driver == null) continue;
      if (g.womenOnly && !facts.isWoman) continue;
      if (g.sameCompanyOnly != null && g.sameCompanyOnly != facts.company) continue;
      if (g.sameCompoundOnly != null && g.sameCompoundOnly != facts.compound) continue;
      if (!PrivacyRules.accepts(
        privacy,
        facts,
        PersonFacts(isWoman: driver.isWoman, company: driver.company, compound: driver.compound),
      )) {
        continue;
      }
      final date = MarketDay.nextDeparture(g.days, g.timeFor(leg), now);
      if (date == null || await ridesOn(date)) continue;
      final source = BookingSource.groupSeat(g.id);
      final free = SeatMath.otherGroupLeg(
        g,
        leg,
        bookings: _holds(source, date, leg, now, all),
        subscriberView: rider.subscriber,
      );
      if (free <= 0) continue;
      seats.add(SeatOffer(
        source: source,
        driver: _driverOf(driver),
        pickup: going && route.home != null ? g.nearestStop(route.home!) : (going ? g.goingStops.first : g.workStop),
        date: date,
        leg: leg,
        departure: g.timeFor(leg),
        freeSeats: free,
        price: SeatPrice.of(g.price, tripCost: g.tripCost, riderSeats: g.riderSeats, mode: rider.mode),
      ));
    }

    seats.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.source.id.compareTo(b.source.id);
    });
    return seats;
  }

  /// A detour of this many minutes or more is not on the way (R14).
  static const _maxDetour = 10;

  static SeatDriver _unknownDriver(String id) => SeatDriver(
    id: id,
    firstName: id,
    initials: id.isEmpty ? '' : id.substring(0, id.length < 2 ? id.length : 2).toUpperCase(),
    rating: 0,
  );

  /// What [source] rides on right now, re-read for a write: null when it is
  /// gone, cancelled or has already left.
  ({String driverId, int tripCost, int riderSeats, int free, String rideId, OfferedTrip? trip})? _seatSource(
    BookingSource source,
    CalendarDate date,
    Leg leg,
    WallTime now,
    List<Booking> all, {
    required bool subscriber,
  }) {
    final holds = _holds(source, date, leg, now, all);
    switch (source.kind) {
      case BookingSourceKind.offer:
        final o = _offers().where((o) => o.id == source.id).firstOrNull;
        if (o == null || o.date != date || o.leg != leg) return null;
        if (o.status != OfferStatus.open && o.status != OfferStatus.full) return null;
        if (MarketDay.isExpired(o.date, o.departure, now)) return null;
        return (
          driverId: o.driverId,
          tripCost: o.tripCost,
          riderSeats: o.riderSeats,
          free: SeatMath.offeredTrip(seats: o.seats, bookings: holds, subscriberView: subscriber),
          rideId: Booking.offerRideId(o.id),
          trip: o,
        );
      case BookingSourceKind.groupSeat:
        final g = _catalog.byId(source.id);
        if (g == null || MarketDay.isExpired(date, g.timeFor(leg), now)) return null;
        return (
          driverId: g.driverFor(leg)?.id ?? '',
          tripCost: g.tripCost,
          riderSeats: g.riderSeats,
          free: SeatMath.otherGroupLeg(g, leg, bookings: holds, subscriberView: subscriber),
          rideId: Ride.idFor(g.id, date, leg),
          trip: null,
        );
      case BookingSourceKind.request:
        return null;
    }
  }

  @override
  Future<BookResult> book(SeatOffer offer, {required WallTime now}) async {
    final me = _daily.meId;
    final all = _bookings();
    if (await _ridesLeg(offer.date, offer.leg, [for (final b in all) if (b.riderId == me) b])) {
      return const AlreadyRiding();
    }
    final rider = await _rider(now);

    // Re-check inside the write: the list may be stale (SC-006).
    final basis = _seatSource(offer.source, offer.date, offer.leg, now, all, subscriber: rider.subscriber);
    if (basis == null || basis.free <= 0) return const SeatTaken();

    final price = SeatPrice.of(
      offer.price.contribution,
      tripCost: basis.tripCost,
      riderSeats: basis.riderSeats,
      mode: rider.mode,
    );
    final check = BookingGate.check(
      hasArrangement: rider.hasArrangement,
      mode: rider.mode,
      cashOffered: price.cashOffered,
      balance: rider.balance,
      price: price,
    );
    switch (check.kind) {
      case BookingCheckKind.needsMethod:
        return const BookNeedsMethod();
      case BookingCheckKind.topUp:
        return BookTopUp(check.gap);
      case BookingCheckKind.ok:
        break;
    }

    final id = _nextBookingId(all);
    final cash = rider.mode == PricingMode.cash && price.cashOffered;
    if (!cash) {
      final paid = await ledger().debitSeat(
        me,
        bookingId: id,
        rideId: basis.rideId,
        total: price.total,
        fee: price.fee,
        date: offer.date,
      );
      if (paid == PaymentResult.failure) return const PaymentFailed();
    }

    final booking = Booking(
      id: id,
      riderId: me,
      riderName: rider.profile.firstName,
      rider: AnonymousRider(
        isWoman: rider.profile.isWoman,
        rating: rider.profile.rating > 0 ? rider.profile.rating : null,
      ),
      source: offer.source,
      date: offer.date,
      leg: offer.leg,
      rideId: basis.rideId,
      price: price,
      paidBy: cash ? PaidBy.cash : (rider.subscriber ? PaidBy.plan : PaidBy.wallet),
      paid: cash ? 0 : price.total,
      bookedAt: now,
      isSubscriber: rider.subscriber,
    );
    await _writeList(bookingsKey, [...all, booking], (b) => b.toJson());

    // The last physical seat marks the offer full (a subscriber's view may still list it).
    final trip = basis.trip;
    if (trip != null) {
      final taken = SeatMath.offeredTrip(
        seats: trip.seats,
        bookings: _holds(offer.source, offer.date, offer.leg, now, [...all, booking]),
      );
      if (taken <= 0) await _saveOffer(trip.copyWith(status: OfferStatus.full));
    }

    await notices.post(NoticeKind.seatBooked, {'day': offer.date.toIso(), 'driver': offer.driver.firstName});
    return Booked(booking);
  }

  @override
  Future<CancelResult> cancelBooking(String bookingId, {required WallTime now}) async {
    final me = _daily.meId;
    final all = _bookings();
    final b = all.where((b) => b.id == bookingId && b.riderId == me).firstOrNull;
    if (b == null || b.status != BookingStatus.booked) return const NotCancellable();
    final trip = _tripOf(b);
    if (trip == null || !AttendanceRules.canCancel(trip.start, now)) return const NotCancellable();

    // 003's rule on the contribution only; the fee always goes back (R7).
    final owed = AttendanceRules.cancelCharge(b.date, now, b.price.contribution);
    final refund = BookingRefund.amount(paidTotal: b.paid, fee: b.price.fee, owed: owed);
    if (refund > 0) {
      await ledger().refundSeat(me, bookingId: b.id, rideId: b.rideId, amount: refund, date: b.date);
    }
    if (owed > 0) {
      await _writeList(
        chargesKey,
        [
          ...charges(),
          Charge(
            id: 'ch-${b.id}',
            personId: me,
            rideId: b.rideId,
            reason: ChargeReason.lateCancel,
            amount: owed,
            owedTo: trip.driverId,
          ),
        ],
        (c) => c.toJson(),
      );
    }
    await _writeList(
      bookingsKey,
      [for (final x in all) x.id == b.id ? x.copyWith(status: BookingStatus.cancelled) : x],
      (x) => x.toJson(),
    );

    // A full car has a seat again.
    if (b.source.kind == BookingSourceKind.offer) {
      final o = _offers().where((o) => o.id == b.source.id).firstOrNull;
      if (o != null && o.status == OfferStatus.full) await _saveOffer(o.copyWith(status: OfferStatus.open));
    }
    return BookingCancelled(refund);
  }

  /// Late-cancel charges the marketplace owes drivers (a 003-style [Charge],
  /// no Goora fee).
  List<Charge> charges() => _read(chargesKey, Charge.fromJson);

  @override
  Future<SeatOffer?> seatOf(Booking b) async {
    switch (b.source.kind) {
      case BookingSourceKind.offer:
        final o = _offers().where((o) => o.id == b.source.id).firstOrNull;
        if (o == null) return null;
        return SeatOffer(
          source: b.source,
          driver: MarketSeed.driverById(o.driverId) ?? _unknownDriver(o.driverId),
          pickup: o.pickup,
          date: b.date,
          leg: b.leg,
          departure: o.departure,
          freeSeats: 0,
          price: b.price,
          from: o.from,
          to: o.to,
          arrival: _tripOf(b)?.end.time,
        );
      case BookingSourceKind.groupSeat:
        final g = _catalog.byId(b.source.id);
        final driver = g?.driverFor(b.leg);
        if (g == null || driver == null) return null;
        final home = (await _route(b.leg))?.home;
        final going = b.leg == Leg.going;
        return SeatOffer(
          source: b.source,
          driver: _driverOf(driver),
          pickup: going && home != null ? g.nearestStop(home) : (going ? g.goingStops.first : g.workStop),
          date: b.date,
          leg: b.leg,
          departure: g.timeFor(b.leg),
          freeSeats: 0,
          price: b.price,
          from: going ? g.origin : g.destination,
          to: going ? g.destination : g.origin,
          arrival: g.endFor(b.leg),
        );
      case BookingSourceKind.request:
        // An accepted request rides the driver's own trip; US2 gives it a face.
        return null;
    }
  }

  @override
  Future<List<Booking>> myBookings({required WallTime now}) async {
    final me = _daily.meId;
    final live = <(WallTime, Booking)>[];
    for (final b in _bookings()) {
      if (b.riderId != me || b.status != BookingStatus.booked) continue;
      final trip = _tripOf(b);
      if (trip != null && !now.isBefore(trip.end)) continue;
      live.add((trip?.start ?? WallTime(b.date, const Clock.hm(0, 0)), b));
    }
    live.sort((a, b) {
      final byStart = a.$1.compareTo(b.$1);
      return byStart != 0 ? byStart : a.$2.id.compareTo(b.$2.id);
    });
    return [for (final e in live) e.$2];
  }

  // --------------------------------------------------------------- writes

  static String _nextBookingId(List<Booking> all) {
    var top = 0;
    for (final b in all) {
      final n = int.tryParse(b.id.startsWith('bk-') ? b.id.substring(3) : '');
      if (n != null && n > top) top = n;
    }
    return 'bk-${top + 1}';
  }

  /// Writes [trip] over its stored copy (or appends it): a seeded offer is
  /// only ever stored once it changes.
  Future<void> _saveOffer(OfferedTrip trip) async {
    final stored = _read(offersKey, OfferedTrip.fromJson);
    final next = [for (final o in stored) o.id == trip.id ? trip : o];
    if (!next.any((o) => o.id == trip.id)) next.add(trip);
    await _writeList(offersKey, next, (o) => o.toJson());
  }

  Future<void> _writeList<T>(String key, List<T> items, Map<String, Object?> Function(T) toJson) =>
      _prefs.setString(key, jsonEncode([for (final i in items) toJson(i)]));

  // --------------------------------------------- stories (later phases)

  @override
  Future<PostResult> post(TripDraft draft, {required WallTime now}) => throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<void> cancelRequest(String requestId) => throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<TripRequest?> request(String requestId, {required WallTime now}) =>
      throw UnimplementedError('Phase 7 (US3)');

  @override
  Future<int> driversOnRoute(TripDraft draft) => throw UnimplementedError('Phase 7 (US3)');

  // ------------------------------------------------------ C: Offer a trip

  static String _nextOfferId(List<OfferedTrip> all) {
    var top = 0;
    for (final o in all) {
      final n = int.tryParse(o.id.startsWith('of-') ? o.id.substring(3) : '');
      if (n != null && n > top) top = n;
    }
    return 'of-${top + 1}';
  }

  @override
  Future<PublishResult> publish(OfferDraft draft, {required WallTime now}) async {
    final profile = await trust.profile();
    final missing = [
      for (final item in profile.items)
        if (publishChecks.contains(item.kind) && item.status != VerificationStatus.verified) item.kind,
    ];
    if (missing.isNotEmpty) return NotVerified(missing);

    // The stepper never lets a price out of range; reaching here with one is a bug (FR-022).
    final range = PricingService.range(MarketSeed.tripCost, draft.seats);
    if (!range.contains(draft.contribution)) {
      throw ArgumentError.value(draft.contribution, 'contribution', 'outside ${range.min}–${range.max} EGP');
    }

    final date = MarketDay.nextWorkday(draft.departure, now);
    final day = await driverDay(date);
    final fit = DriverDayRules.fit(
      day.trips,
      Candidate(
        leg: draft.leg,
        from: draft.from,
        to: draft.to,
        departure: draft.departure.minutes,
        durationMinutes: _tripMinutes,
        daily: draft.repeat == Repeat.daily,
        leadsGroup: day.leadsGroup,
      ),
    );
    if (fit.kind != TripFitKind.create) return OverLimit(fit);

    final all = _offers();
    final id = _nextOfferId(all);
    final trip = OfferedTrip(
      id: id,
      driverId: _daily.meId,
      leg: draft.leg,
      from: draft.from,
      to: draft.to,
      date: date,
      departure: draft.departure,
      durationMinutes: _tripMinutes,
      seats: draft.seats,
      riderSeats: draft.seats,
      tripCost: MarketSeed.tripCost,
      contribution: draft.contribution,
      repeat: draft.repeat,
      pickup: MarketSeed.pickupIn(draft.from, 'of-stop-$id', draft.departure),
    );
    await _saveOffer(trip);
    return Published(trip);
  }

  /// Minutes a published trip is assumed to take: the corridor's.
  static const _tripMinutes = 40;

  /// open|full → departed → done follow the clock, without being stored.
  static OfferedTrip _onClock(OfferedTrip o, WallTime now) {
    if (o.status != OfferStatus.open && o.status != OfferStatus.full) return o;
    final start = WallTime(o.date, o.departure);
    if (now.isBefore(start)) return o;
    return o.copyWith(
      status: now.isBefore(start.plusMinutes(o.durationMinutes)) ? OfferStatus.departed : OfferStatus.done,
    );
  }

  @override
  Future<OfferedTrip?> offer(String tripId, {required WallTime now}) async {
    final o = _offers().where((o) => o.id == tripId).firstOrNull;
    return o == null ? null : _onClock(o, now);
  }

  @override
  Future<OfferLive> live(String tripId, {required WallTime now}) async {
    final o = _offers().where((o) => o.id == tripId).firstOrNull;
    if (o == null) throw StateError('no offer $tripId');
    final departed = !now.isBefore(WallTime(o.date, o.departure));
    final riders = [for (final b in _bookings()) if (b.source == BookingSource.offer(o.id) && _holdsSeat(b)) b]
      ..sort((a, b) {
        final byTime = a.bookedAt.compareTo(b.bookedAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    return OfferLive(
      trip: _onClock(o, now),
      // A name only from departure (R15, FR-023).
      riders: [
        for (final b in riders)
          LiveRider(
            rider: b.rider,
            firstName: departed ? b.riderName : null,
            riderId: b.riderId,
            paidBy: b.paidBy,
            price: b.price,
          ),
      ],
    );
  }

  @override
  Future<void> cancelOffer(String tripId, {required WallTime now}) async {
    final o = _offers().where((o) => o.id == tripId).firstOrNull;
    if (o == null || (o.status != OfferStatus.open && o.status != OfferStatus.full)) return;
    final me = _daily.meId;
    final all = _bookings();
    final held = [for (final b in all) if (b.source == BookingSource.offer(o.id) && b.status == BookingStatus.booked) b];

    for (final b in held) {
      // Full refund, fee included (SC-005). A fake rider has no wallet here.
      if (b.riderId == me && b.paid > 0) {
        await ledger().refundSeat(me, bookingId: b.id, rideId: b.rideId, amount: b.paid, date: b.date);
      }
      await notices.post(NoticeKind.tripCancelledByDriver, {
        'day': o.date.toIso(),
        'driver': (await trust.profile()).firstName,
      });
    }
    await _writeList(
      bookingsKey,
      [for (final b in all) held.any((h) => h.id == b.id) ? b.copyWith(status: BookingStatus.refunded) : b],
      (b) => b.toJson(),
    );
    await _saveOffer(o.copyWith(status: OfferStatus.cancelled, cancelledWithRiders: held.isNotEmpty));

    // Only a late cancel with riders counts against the driver (R9, FR-017).
    if (held.isNotEmpty && AttendanceRules.isLate(o.date, now)) {
      await notices.recordReliability(
        ReliabilityEvent(
          personId: o.driverId,
          rideId: Booking.offerRideId(o.id),
          date: o.date,
          kind: ReliabilityEventKind.lateCantDrive,
        ),
      );
    }
  }

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

  /// Settings → "A rider books your seat": the next fake rider takes a seat on
  /// the driver's latest open offer. A daily offer's first booking turns it
  /// into a commute group (research R10).
  @override
  Future<DemoResult> demoRiderBooks({required WallTime now}) async {
    final me = _daily.meId;
    final mine = [
      for (final o in _offers())
        if (o.driverId == me && o.status == OfferStatus.open && !MarketDay.isExpired(o.date, o.departure, now)) o,
    ];
    if (mine.isEmpty) return const DemoNothing();
    final o = mine.last;

    final source = BookingSource.offer(o.id);
    final all = _bookings();
    final holds = _holds(source, o.date, o.leg, now, all);
    if (SeatMath.offeredTrip(seats: o.seats, bookings: holds) <= 0) return const DemoNothing();

    final taken = {for (final b in all) if (b.source == source && _holdsSeat(b)) b.riderId};
    final cursor = _prefs.getInt(seedCursorKey) ?? 0;
    const pool = MarketSeed.riders;
    final seed = [for (var i = 0; i < pool.length; i++) pool[(cursor + i) % pool.length]]
        .where((r) => !taken.contains(r.id))
        .firstOrNull;
    if (seed == null) return const DemoNothing();
    await _prefs.setInt(seedCursorKey, pool.indexOf(seed) + 1);

    final price = MarketSeed.quote(o.contribution);
    final booking = Booking(
      id: _nextBookingId(all),
      riderId: seed.id,
      riderName: seed.firstName,
      rider: seed.rider,
      source: source,
      date: o.date,
      leg: o.leg,
      rideId: Booking.offerRideId(o.id),
      price: price,
      paidBy: PaidBy.wallet,
      paid: price.total,
      bookedAt: now,
      isSubscriber: false,
    );
    final isFirst = !all.any((b) => b.source == source && _holdsSeat(b));
    await _writeList(bookingsKey, [...all, booking], (b) => b.toJson());

    if (o.repeat == Repeat.daily && isFirst && await _commute.joinedGroupId() == null) {
      await _becomeGroup(o, seed, now);
    } else if (SeatMath.offeredTrip(seats: o.seats, bookings: _holds(source, o.date, o.leg, now, [...all, booking])) <= 0) {
      await _saveOffer(o.copyWith(status: OfferStatus.full));
    }
    return const DemoDone();
  }

  /// A daily offer's first booking: a real 003 group on the one leg, the
  /// driver joined to it, the booker its first rider, and every booking on the
  /// offer re-keyed to the group's ride so 004 bills the ride once (R10).
  Future<void> _becomeGroup(OfferedTrip o, SeedRider first, WallTime now) async {
    final groupId = '${GroupCatalog.createdPrefix}${o.id}';
    final going = o.leg == Leg.going;
    final free = o.seats - 1;
    await _catalog.create(CommuteGroup(
      id: groupId,
      origin: o.from,
      destination: o.to,
      destinationPoint: MarketSeed.pointIn(o.to),
      pickupPoints: [o.pickup.point],
      going: o.departure,
      ret: o.departure,
      days: MarketDay.workdays,
      members: [
        Member(
          id: first.id,
          firstName: first.firstName,
          initials: first.firstName.substring(0, 1).toUpperCase(),
          role: MemberRole.rider,
          isWoman: first.rider.isWoman,
          rating: first.rider.rating ?? 0,
          reliability: 100,
          legs: {o.leg},
        ),
      ],
      price: o.contribution,
      freeSeatsGoing: going ? free : 0,
      freeSeatsReturn: going ? 0 : free,
      detourMinutes: 0,
      tripCost: o.tripCost,
      riderSeats: o.riderSeats,
      stops: [o.pickup],
      arrival: o.departure.shift(o.durationMinutes),
      arrivalName: MarketSeed.pickupIn(o.to, '', o.departure).name,
      // The Sunday of the offer's week: the rotation starts with it.
      rotationStart: o.date.addDays(-o.date.weekday.index),
    ));
    await _commute.join(groupId);

    final rideId = Ride.idFor(groupId, o.date, o.leg);
    final source = BookingSource.offer(o.id);
    await _writeList(
      bookingsKey,
      [for (final b in _bookings()) b.source == source ? b.copyWith(rideId: rideId) : b],
      (b) => b.toJson(),
    );
    await _saveOffer(o.copyWith(status: OfferStatus.grouped, groupId: groupId));
  }

  @override
  Future<DemoResult> demoSubscriberTakes({required WallTime now}) => throw UnimplementedError('its story (debug demo, FR-028)');
}

typedef _TripInfo = ({String driverId, int tripCost, int riderSeats, WallTime start, WallTime end});

/// The signed-in rider as the marketplace prices and gates them.
final class _Rider {
  const _Rider({
    required this.profile,
    required this.mode,
    required this.hasArrangement,
    required this.balance,
    required this.subscriber,
  });

  final TrustProfile profile;
  final PricingMode mode;
  final bool hasArrangement;
  final int balance;
  final bool subscriber;
}
