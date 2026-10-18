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
import '../../wallet/domain/seat_price.dart';
import '../../wallet/domain/share.dart';
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

  /// Next index into the fake driver pool for "A driver accepts your request".
  static const driverCursorKey = 'market.driverCursor';

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
        riderName: b.riderName,
        driverName: trip.driverName,
        end: trip.end,
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
      driverName: MarketSeed.driverById(o.driverId)?.firstName ?? o.driverId,
      tripCost: o.tripCost,
      riderSeats: o.riderSeats,
      start: WallTime(o.date, o.departure),
      end: WallTime(o.date, o.departure).plusMinutes(o.durationMinutes),
    );
  }

  _TripInfo? _groupTrip(String groupId, Booking b) {
    final g = _catalog.byId(groupId);
    if (g == null) return null;
    final driver = g.driverFor(b.leg);
    return (
      driverId: driver?.id ?? '',
      driverName: driver?.firstName ?? '',
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
      plan: plan,
      today: now.date,
      trialAvailable: data.cashTrial?.available ?? false,
    );
    return _Rider(
      profile: profile,
      mode: mode,
      method: data.method ?? PaymentMethod.cash,
      hasArrangement: data.method != null || covered,
      openShares: data.shares,
      feeOverdue: data.feeOverdue ? data.owed : 0,
      idOk: (await trust.riderIdStatus()).ok,
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
        price: SeatPrice.of(o.contribution,
            tripCost: o.tripCost, riderSeats: o.riderSeats, mode: rider.mode, method: rider.method),
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
        price: SeatPrice.of(g.price,
            tripCost: g.tripCost, riderSeats: g.riderSeats, mode: rider.mode, method: rider.method),
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
    var all = _bookings();
    if (await _ridesLeg(offer.date, offer.leg, [for (final b in all) if (b.riderId == me) b])) {
      return const AlreadyRiding();
    }
    final rider = await _rider(now);

    // Re-check inside the write: the list may be stale (SC-006).
    final basis = _seatSource(offer.source, offer.date, offer.leg, now, all, subscriber: rider.subscriber);
    if (basis == null || basis.free <= 0) return const SeatTaken();

    // A subscriber may take the newest still-reclaimable seat of a full car (US6 AC1).
    if (rider.subscriber) {
      final physical = _seatSource(offer.source, offer.date, offer.leg, now, all, subscriber: false);
      if (physical != null && physical.free <= 0) {
        final takeable = [
          for (final b in all)
            if (b.source == offer.source && b.date == offer.date && b.leg == offer.leg && b.reclaimable(now)) b,
        ]..sort((a, b) {
            final byTime = b.bookedAt.compareTo(a.bookedAt);
            return byTime != 0 ? byTime : b.id.compareTo(a.id);
          });
        if (takeable.isEmpty) return const SeatTaken();
        await _reclaim(takeable.first, all);
        all = _bookings();
      }
    }

    final price = SeatPrice.of(
      offer.price.contribution,
      tripCost: basis.tripCost,
      riderSeats: basis.riderSeats,
      mode: rider.mode,
      method: rider.method,
    );
    final check = BookingGate.check(
        hasArrangement: rider.hasArrangement,
        openShares: rider.openShares,
        feeOverdue: rider.feeOverdue,
        idOk: rider.idOk);
    switch (check.kind) {
      case BookingCheckKind.owesDriver:
        return BookOwesDriver(check.amount, check.driverFirstName);
      case BookingCheckKind.feeOverdue:
        return BookFeeOverdue(check.amount);
      case BookingCheckKind.needsId:
        return const BookNeedsId();
      case BookingCheckKind.needsMethod:
        return const BookNeedsMethod();
      case BookingCheckKind.ok:
        break;
    }

    // Only Goora's fee is recorded; the share is paid to the driver (007 R5).
    final id = _nextBookingId(all);
    final cash = rider.mode == PricingMode.trial;
    if (!cash) {
      await ledger().debitSeat(
        me,
        bookingId: id,
        rideId: basis.rideId,
        fee: price.fee,
        share: price.share,
        date: offer.date,
      );
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
      paid: cash ? 0 : price.fee,
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
    // The owed share is the driver's, paid directly (007 R5): only a 005 row
    // that still holds the share (paid above the fee) has it kept back.
    final refund = BookingRefund.amount(paidTotal: b.paid, fee: b.price.fee, owed: b.paid > b.price.fee ? owed : 0);
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

  // ------------------------------------------------------ B: Post your trip

  /// A first name for a rider who is only an id in the fake data, stable for
  /// the same id (the name shows only from departure, R15).
  static String _seedFirstName(String riderId) {
    const pool = MarketSeed.riders;
    return pool[riderId.codeUnits.fold<int>(0, (a, b) => a + b) % pool.length].firstName;
  }

  static Member _riderMember(String id, String name, AnonymousRider rider, Leg leg) => Member(
        id: id,
        firstName: name,
        initials: name.isEmpty ? '' : name.substring(0, 1).toUpperCase(),
        role: MemberRole.rider,
        isWoman: rider.isWoman,
        rating: rider.rating ?? 0,
        reliability: 100,
        legs: {leg},
      );

  static Member _driverMember(SeatDriver d, Leg leg) => Member(
        id: d.id,
        firstName: d.firstName,
        initials: d.initials,
        role: MemberRole.driver,
        isWoman: d.isWoman,
        rating: d.rating,
        reliability: 100,
        legs: {leg},
        seats: MarketSeed.riderSeats,
        vehicle: const Vehicle(make: 'Kia Cerato', colour: VehicleColour.grey),
      );

  /// The one-leg group a daily trip becomes (research R10).
  static CommuteGroup _oneLegGroup({
    required String id,
    required Leg leg,
    required Area from,
    required Area to,
    required Stop pickup,
    required int durationMinutes,
    required int price,
    required int tripCost,
    required int riderSeats,
    required int seatsTaken,
    required List<Member> members,
    required CalendarDate date,
  }) {
    final going = leg == Leg.going;
    final free = riderSeats - seatsTaken < 0 ? 0 : riderSeats - seatsTaken;
    // A group runs home → work: its stops are at home and its work stop is
    // where the return leg starts. A return trip is the other way round
    // (T104 F10), so its pickup is the work stop and it ends at a home stop.
    final home = going ? from : to;
    final work = going ? to : from;
    final homeStop = going ? pickup : MarketSeed.pickupIn(home, pickup.id, pickup.time.shift(durationMinutes));
    return CommuteGroup(
      id: id,
      origin: home,
      destination: work,
      destinationPoint: going ? MarketSeed.pointIn(work) : pickup.point,
      pickupPoints: [homeStop.point],
      going: pickup.time,
      ret: pickup.time,
      days: MarketDay.workdays,
      members: members,
      price: price,
      freeSeatsGoing: going ? free : 0,
      freeSeatsReturn: going ? 0 : free,
      detourMinutes: 0,
      tripCost: tripCost,
      riderSeats: riderSeats,
      stops: [homeStop],
      arrival: pickup.time.shift(durationMinutes),
      arrivalName: going ? MarketSeed.pickupIn(work, '', pickup.time).name : pickup.name,
      // The Sunday of the trip's week: the rotation starts with it.
      rotationStart: date.addDays(-date.weekday.index),
    );
  }

  static String _nextRequestId(List<TripRequest> all) {
    var top = 0;
    for (final r in all) {
      final n = int.tryParse(r.id.startsWith('rq-') ? r.id.substring(3) : '');
      if (n != null && n > top) top = n;
    }
    return 'rq-${top + 1}';
  }

  Future<void> _saveRequest(TripRequest request) async {
    final stored = _read(requestsKey, TripRequest.fromJson);
    final next = [for (final r in stored) r.id == request.id ? request : r];
    if (!next.any((r) => r.id == request.id)) next.add(request);
    await _writeList(requestsKey, next, (r) => r.toJson());
  }

  /// What a posted request costs its rider: the suggested contribution of the
  /// corridor's standard 3 seats, priced for the rider's arrangement and fixed
  /// from then on (R6, FR-022).
  SeatPrice _requestPrice(_Rider rider) => SeatPrice.of(
        PricingService.range(MarketSeed.tripCost, MarketSeed.riderSeats).suggested,
        tripCost: MarketSeed.tripCost,
        riderSeats: MarketSeed.riderSeats,
        mode: rider.mode,
        method: rider.method,
      );

  @override
  Future<PostResult> post(TripDraft draft, {required WallTime now}) async {
    final rider = await _rider(now);
    if (!rider.hasArrangement) return const PostNeedsMethod();
    if (draft.repeat == Repeat.daily && await _daily.myGroup() != null) return const DailyNotAllowed();

    final price = _requestPrice(rider);
    final check = BookingGate.check(
        hasArrangement: rider.hasArrangement,
        openShares: rider.openShares,
        feeOverdue: rider.feeOverdue,
        idOk: rider.idOk);
    switch (check.kind) {
      case BookingCheckKind.owesDriver:
        return PostOwesDriver(check.amount, check.driverFirstName);
      case BookingCheckKind.feeOverdue:
        return PostFeeOverdue(check.amount);
      case BookingCheckKind.needsId:
        return const PostNeedsId();
      case BookingCheckKind.needsMethod:
        return const PostNeedsMethod();
      case BookingCheckKind.ok:
        break;
    }

    final id = _nextRequestId(_requests());
    final request = TripRequest(
      id: id,
      riderId: _daily.meId,
      rider: AnonymousRider(isWoman: rider.profile.isWoman, rating: rider.profile.rating > 0 ? rider.profile.rating : null),
      leg: draft.leg,
      from: draft.from,
      to: draft.to,
      date: MarketDay.nextWorkday(draft.departure, now),
      departure: draft.departure,
      repeat: draft.repeat,
      pickup: MarketSeed.pickupIn(draft.from, 'rq-stop-$id', draft.departure),
      detourFrom: {for (final a in Area.values) a: a == draft.from ? 3 : 6},
      price: price,
    );
    await _saveRequest(request);
    return Posted(request);
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    final r = _requests().where((r) => r.id == requestId).firstOrNull;
    if (r == null || r.status != RequestStatus.posted) return;
    await _saveRequest(r.copyWith(status: RequestStatus.cancelled));
  }

  @override
  Future<List<TripRequest>> myRequests({required WallTime now}) async {
    final me = _daily.meId;
    final live = <TripRequest>[];
    for (final r in _requests()) {
      if (r.riderId != me) continue;
      final fresh = await request(r.id, now: now);
      if (fresh != null && fresh.status == RequestStatus.posted) live.add(fresh);
    }
    live.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return live;
  }

  @override
  Future<TripRequest?> request(String requestId, {required WallTime now}) async {
    final r = _requests().where((r) => r.id == requestId).firstOrNull;
    if (r == null) return null;
    if (r.status == RequestStatus.posted && MarketDay.isExpired(r.date, r.departure, now)) {
      final expired = r.copyWith(status: RequestStatus.expired);
      await _saveRequest(expired);
      if (r.riderId == _daily.meId) await notices.post(NoticeKind.requestExpired, {'day': r.date.toIso()});
      return expired;
    }
    return r;
  }

  @override
  Future<int> driversOnRoute(TripDraft draft) async {
    final profile = await trust.profile();
    return MarketSeed.drivers
        .where((d) => PrivacyRules.accepts(profile.privacy, profile.facts, PersonFacts(isWoman: d.isWoman)))
        .length;
  }

  // -------------------------------------------------- D: Find riders / accept

  @override
  Future<List<RequestCard>> requestsForMe({Area? leavingFrom, required PartOfDay part, required WallTime now}) async {
    final me = _daily.meId;
    final profile = await trust.profile();
    final wanted = part == PartOfDay.morning ? Leg.going : Leg.ret;
    final days = <CalendarDate, DriverDay>{};
    final cards = <RequestCard>[];
    for (final r in _requests()) {
      if (r.status != RequestStatus.posted || r.riderId == me || r.leg != wanted) continue;
      if (MarketDay.isExpired(r.date, r.departure, now)) continue;
      // The driver's own privacy choice decides whom they see (FR-023).
      if (!PrivacyRules.accepts(profile.privacy, profile.facts, PersonFacts(isWoman: r.rider.isWoman))) continue;
      final detour = leavingFrom != null
          ? r.detourFrom[leavingFrom]
          : (r.detourFrom.values.isEmpty ? null : r.detourFrom.values.reduce((a, b) => a < b ? a : b));
      if (detour == null || detour >= _maxDetour) continue;
      final day = days[r.date] ??= await driverDay(r.date);
      final fit = DriverDayRules.fit(day.trips, _candidate(r, day.leadsGroup));
      cards.add(RequestCard(
        requestId: r.id,
        leg: r.leg,
        from: r.from,
        to: r.to,
        rider: r.rider,
        pickup: r.pickup,
        date: r.date,
        departure: r.departure,
        repeat: r.repeat,
        price: r.price,
        detourMinutes: detour,
        fit: fit,
        joinTime: fit.kind == TripFitKind.join ? Clock(day.trips.firstWhere((t) => t.id == fit.tripId).departure) : null,
      ));
    }
    cards.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.requestId.compareTo(b.requestId);
    });
    return cards;
  }

  static Candidate _candidate(TripRequest r, bool leadsGroup) => Candidate(
        leg: r.leg,
        from: r.from,
        to: r.to,
        departure: r.departure.minutes,
        durationMinutes: _tripMinutes,
        daily: r.repeat == Repeat.daily,
        leadsGroup: leadsGroup,
      );

  /// A seat for [r]'s rider on [rideId], created from the request: the rider
  /// paid at accept (or pays cash after), like any one-off seat (R7).
  Booking _requestBooking(
    TripRequest r, {
    required String id,
    required BookingSource source,
    required String rideId,
    required WallTime now,
    required String riderName,
    required PaidBy paidBy,
    required int paid,
    required bool subscriber,
  }) =>
      Booking(
        id: id,
        riderId: r.riderId,
        riderName: riderName,
        rider: r.rider,
        source: source,
        date: r.date,
        leg: r.leg,
        rideId: rideId,
        price: r.price,
        paidBy: paidBy,
        paid: paid,
        bookedAt: now,
        isSubscriber: subscriber,
      );

  Future<void> _markAccepted(TripRequest r, String driverId, String tripId) =>
      _saveRequest(r.copyWith(status: RequestStatus.accepted, acceptedBy: driverId, tripId: tripId));

  /// The driver (the signed-in person) accepts [requestId] (D). The request's
  /// rider is a fake rider whose payment is theirs alone, so no money moves
  /// here; a trip created this way keeps the request's basis (R6).
  @override
  Future<AcceptResult> accept(String requestId, {required WallTime now}) async {
    final me = _daily.meId;
    final r = _requests().where((r) => r.id == requestId).firstOrNull;
    if (r == null || r.status != RequestStatus.posted || r.riderId == me || MarketDay.isExpired(r.date, r.departure, now)) {
      return const RiderCantPay();
    }
    final day = await driverDay(r.date);
    final fit = DriverDayRules.fit(day.trips, _candidate(r, day.leadsGroup));
    final name = _seedFirstName(r.riderId);
    final all = _bookings();
    final paid = r.price.mode == PricingMode.trial ? 0 : r.price.fee;
    final paidBy = paid == 0 ? PaidBy.cash : PaidBy.wallet;

    switch (fit.kind) {
      case TripFitKind.create:
        if (r.repeat == Repeat.daily) {
          final groupId = '${GroupCatalog.createdPrefix}${r.id}';
          await _catalog.create(_oneLegGroup(
            id: groupId,
            leg: r.leg,
            from: r.from,
            to: r.to,
            pickup: r.pickup,
            durationMinutes: _tripMinutes,
            price: r.price.contribution,
            tripCost: MarketSeed.tripCost,
            riderSeats: MarketSeed.riderSeats,
            seatsTaken: 1,
            members: [_riderMember(r.riderId, name, r.rider, r.leg)],
            date: r.date,
          ));
          await _commute.join(groupId);
          await _markAccepted(r, me, Ride.idFor(groupId, r.date, r.leg));
          return AcceptCreated(fit.tripsLeftAfter!);
        }
        final offers = _offers();
        final trip = OfferedTrip(
          id: _nextOfferId(offers),
          driverId: me,
          leg: r.leg,
          from: r.from,
          to: r.to,
          date: r.date,
          departure: r.departure,
          durationMinutes: _tripMinutes,
          seats: MarketSeed.riderSeats,
          riderSeats: MarketSeed.riderSeats,
          tripCost: MarketSeed.tripCost,
          contribution: r.price.contribution,
          repeat: Repeat.once,
          pickup: r.pickup,
          origin: OfferOrigin.fromRequest,
        );
        await _saveOffer(trip);
        await _writeList(
          bookingsKey,
          [
            ...all,
            _requestBooking(
              r,
              id: _nextBookingId(all),
              source: BookingSource.offer(trip.id),
              rideId: Booking.offerRideId(trip.id),
              now: now,
              riderName: name,
              paidBy: paidBy,
              paid: paid,
              subscriber: false,
            ),
          ],
          (b) => b.toJson(),
        );
        await _markAccepted(r, me, trip.id);
        return AcceptCreated(fit.tripsLeftAfter!);

      case TripFitKind.join:
        final tripId = fit.tripId!;
        final trip = day.trips.firstWhere((t) => t.id == tripId);
        if (tripId.contains(':')) {
          // One of my group's legs: a daily rider joins the group, a once rider books that day's seat.
          final groupId = tripId.split(':').first;
          if (r.repeat == Repeat.daily) {
            await _catalog.addMember(groupId, _riderMember(r.riderId, name, r.rider, r.leg));
          } else {
            await _writeList(
              bookingsKey,
              [
                ...all,
                _requestBooking(
                  r,
                  id: _nextBookingId(all),
                  source: BookingSource.groupSeat(groupId),
                  rideId: tripId,
                  now: now,
                  riderName: name,
                  paidBy: paidBy,
                  paid: paid,
                  subscriber: false,
                ),
              ],
              (b) => b.toJson(),
            );
          }
        } else {
          final booking = _requestBooking(
            r,
            id: _nextBookingId(all),
            source: BookingSource.offer(tripId),
            rideId: Booking.offerRideId(tripId),
            now: now,
            riderName: name,
            paidBy: paidBy,
            paid: paid,
            subscriber: false,
          );
          await _writeList(bookingsKey, [...all, booking], (b) => b.toJson());
          final offer = _offers().where((o) => o.id == tripId).firstOrNull;
          if (offer != null &&
              SeatMath.offeredTrip(
                    seats: offer.seats,
                    bookings: _holds(BookingSource.offer(tripId), offer.date, offer.leg, now, [...all, booking]),
                  ) <=
                  0) {
            await _saveOffer(offer.copyWith(status: OfferStatus.full));
          }
        }
        await _markAccepted(r, me, tripId);
        return AcceptJoined(Clock(trip.departure));

      case TripFitKind.full || TripFitKind.limitReached || TripFitKind.doesntFit || TripFitKind.oneGroupOnly || TripFitKind.overlap:
        return AcceptRefused(fit);
    }
  }

  /// Settings → "A driver accepts your request": the next fake driver takes
  /// the person's latest posted request. The gate is checked again here; a
  /// rider who can no longer pay has the request withdrawn and nothing is
  /// charged (R8). A daily request becomes a group and charges nothing now.
  @override
  Future<DemoResult> demoDriverAccepts({required WallTime now}) async {
    final me = _daily.meId;
    final mine = [
      for (final r in _requests())
        if (r.riderId == me && r.status == RequestStatus.posted && !MarketDay.isExpired(r.date, r.departure, now)) r,
    ];
    if (mine.isEmpty) return const DemoNothing();
    final r = mine.last;

    final rider = await _rider(now);
    final check = BookingGate.check(
        hasArrangement: rider.hasArrangement,
        openShares: rider.openShares,
        feeOverdue: rider.feeOverdue,
        idOk: rider.idOk);
    if (check.kind != BookingCheckKind.ok) {
      await _saveRequest(r.copyWith(status: RequestStatus.withdrawn));
      return const DemoDone();
    }

    const pool = MarketSeed.drivers;
    final cursor = _prefs.getInt(driverCursorKey) ?? 0;
    final d = pool[cursor % pool.length];
    await _prefs.setInt(driverCursorKey, cursor + 1);
    final time = '${r.departure.minutes}';

    if (r.repeat == Repeat.daily) {
      final groupId = '${GroupCatalog.createdPrefix}${r.id}';
      await _catalog.create(_oneLegGroup(
        id: groupId,
        leg: r.leg,
        from: r.from,
        to: r.to,
        pickup: r.pickup,
        durationMinutes: _tripMinutes,
        price: r.price.contribution,
        tripCost: MarketSeed.tripCost,
        riderSeats: MarketSeed.riderSeats,
        seatsTaken: 1,
        members: [_driverMember(d, r.leg)],
        date: r.date,
      ));
      await _commute.join(groupId);
      await _markAccepted(r, d.id, Ride.idFor(groupId, r.date, r.leg));
      await notices.post(NoticeKind.requestAccepted, {'driver': d.firstName, 'time': time});
      return const DemoDone();
    }

    final all = _bookings();
    final trip = OfferedTrip(
      id: _nextOfferId(_offers()),
      driverId: d.id,
      leg: r.leg,
      from: r.from,
      to: r.to,
      date: r.date,
      departure: r.departure,
      durationMinutes: _tripMinutes,
      seats: MarketSeed.riderSeats,
      riderSeats: MarketSeed.riderSeats,
      tripCost: MarketSeed.tripCost,
      contribution: r.price.contribution,
      repeat: Repeat.once,
      pickup: r.pickup,
      origin: OfferOrigin.fromRequest,
    );
    final id = _nextBookingId(all);
    final cash = r.price.mode == PricingMode.trial;
    if (!cash) {
      await ledger().debitSeat(
        me,
        bookingId: id,
        rideId: Booking.offerRideId(trip.id),
        fee: r.price.fee,
        share: r.price.share,
        date: r.date,
      );
    }
    await _saveOffer(trip);
    await _writeList(
      bookingsKey,
      [
        ...all,
        _requestBooking(
          r,
          id: id,
          source: BookingSource.offer(trip.id),
          rideId: Booking.offerRideId(trip.id),
          now: now,
          riderName: rider.profile.firstName,
          paidBy: cash ? PaidBy.cash : (rider.subscriber ? PaidBy.plan : PaidBy.wallet),
          paid: cash ? 0 : r.price.fee,
          subscriber: rider.subscriber,
        ),
      ],
      (b) => b.toJson(),
    );
    await _markAccepted(r, d.id, trip.id);
    await notices.post(NoticeKind.requestAccepted, {'driver': d.firstName, 'time': time});
    return const DemoDone();
  }

  // -------------------------------------------- US6: a subscriber takes the seat

  /// Takes [b]'s seat back: everything paid goes back to the booker, the
  /// booker is told, and a full car has a seat again (R7, FR-025).
  Future<int> _reclaim(Booking b, List<Booking> all) async {
    final me = _daily.meId;
    final refund = b.paid;
    if (refund > 0 && b.riderId == me) {
      await ledger().refundSeat(me, bookingId: b.id, rideId: b.rideId, amount: refund, date: b.date);
    }
    await _writeList(
      bookingsKey,
      [for (final x in all) x.id == b.id ? x.copyWith(status: BookingStatus.reclaimed) : x],
      (x) => x.toJson(),
    );
    if (b.source.kind == BookingSourceKind.offer) {
      final o = _offers().where((o) => o.id == b.source.id).firstOrNull;
      if (o != null && o.status == OfferStatus.full) await _saveOffer(o.copyWith(status: OfferStatus.open));
    }
    // A cash seat refunds 0 but still vanishes from Today, so the booker is
    // told either way (T104 F18); the label words a 0 as "nothing to refund".
    if (b.riderId == me) {
      await notices.post(NoticeKind.seatReclaimed, {'day': b.date.toIso(), 'amount': '$refund'});
    }
    return refund;
  }

  @override
  Future<ReclaimResult> reclaim(String bookingId, {required WallTime now}) async {
    final all = _bookings();
    final b = all.where((b) => b.id == bookingId).firstOrNull;
    if (b == null || b.status != BookingStatus.booked) return const NotReclaimable();
    // A subscriber's seat, or one booked after the cut-off, is final (FR-025).
    if (b.isSubscriber || AttendanceRules.isLate(b.date, b.bookedAt)) return const NotReclaimable();
    if (AttendanceRules.isLate(b.date, now)) return const ReclaimTooLate();
    return Reclaimed(await _reclaim(b, all));
  }

  @override
  Future<DemoResult> demoSubscriberTakes({required WallTime now}) async {
    final me = _daily.meId;
    final mine = [for (final b in _bookings()) if (b.riderId == me && b.status == BookingStatus.booked) b]
      ..sort((a, b) {
        final byTime = b.bookedAt.compareTo(a.bookedAt);
        return byTime != 0 ? byTime : b.id.compareTo(a.id);
      });
    if (mine.isEmpty) return const DemoNothing();
    return switch (await reclaim(mine.first.id, now: now)) {
      Reclaimed() => const DemoDone(),
      // A booking made after the cut-off is final from the start (FR-025).
      ReclaimTooLate() || NotReclaimable() => const DemoTooLate(),
    };
  }

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
      paid: price.fee,
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
    await _catalog.create(_oneLegGroup(
      id: groupId,
      leg: o.leg,
      from: o.from,
      to: o.to,
      pickup: o.pickup,
      durationMinutes: o.durationMinutes,
      price: o.contribution,
      tripCost: o.tripCost,
      riderSeats: o.riderSeats,
      seatsTaken: 1,
      members: [_riderMember(first.id, first.firstName, first.rider, o.leg)],
      date: o.date,
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

}

typedef _TripInfo = ({String driverId, String driverName, int tripCost, int riderSeats, WallTime start, WallTime end});

/// The signed-in rider as the marketplace prices and gates them.
final class _Rider {
  const _Rider({
    required this.profile,
    required this.mode,
    required this.method,
    required this.hasArrangement,
    required this.openShares,
    required this.feeOverdue,
    required this.idOk,
    required this.balance,
    required this.subscriber,
  });

  final TrustProfile profile;
  final PricingMode mode;

  /// How they pay the driver (cash / InstaPay).
  final PaymentMethod method;
  final bool hasArrangement;

  /// Shares a driver hasn't confirmed; an open debt blocks booking (007 FR-005).
  final List<Share> openShares;

  /// Goora's owed fees when overdue (008 FR-005), else 0.
  final int feeOverdue;

  /// The rider's ID is checked (009 FR-002).
  final bool idOk;
  final int balance;
  final bool subscriber;
}
