import '../../../core/backend/backend_failure.dart';
import '../../../core/backend/backend_gateway.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';
import '../../commute/domain/clock.dart';
import '../../commute/domain/commute_profile.dart';
import '../../commute/domain/corridor.dart';
import '../../commute/domain/group.dart';
import '../../commute/domain/place.dart';
import '../../commute/domain/pricing_service.dart';
import '../../daily/domain/daily_commute_repository.dart';
import '../../daily/domain/privacy.dart';
import '../../daily/domain/ride.dart';
import '../../daily/domain/trust.dart';
import '../../daily/domain/trust_repository.dart';
import '../../wallet/domain/done_one_off.dart';
import '../../wallet/domain/payment_method.dart';
import '../../wallet/domain/seat_price.dart';
import '../../wallet/domain/wallet_repository.dart';
import '../domain/anonymous_rider.dart';
import '../domain/booking.dart';
import '../domain/booking_gate.dart';
import '../domain/driver_day.dart';
import '../domain/driver_day_rules.dart';
import '../domain/market_day.dart';
import '../domain/marketplace_repository.dart';
import '../domain/offered_trip.dart';
import '../domain/seat_math.dart';
import '../domain/seat_offer.dart';
import '../domain/trip_request.dart';
import 'market_seed.dart';

/// The seat marketplace on the server (005 tables, 011 research D16). Reads
/// go to `offered_trips` / `trip_requests` / `bookings` under their RLS; every
/// write is a `market_*` function that re-checks inside the transaction: the
/// 2-a-day cap, the seat count, the price cap (constitution II) and one
/// booking per rider per leg-date.
///
/// The price and the booking gate are worked out on the device first, with
/// the same rules as the fake (PricingService, SeatPrice, BookingGate), so
/// the screens get the same answers; the server is the backstop.
///
/// Other people's names reach this seam only through narrow server functions —
/// `market_offer_cards` (driver first name, rating, initials),
/// `market_requests_for` (no rider id or name), `market_done_one_offs` (first
/// names of finished trips) — because `profiles` stays owner-only (013 D6, D8).
/// The demo actions do nothing against a real server.
final class SupabaseMarketplaceRepository implements MarketplaceRepository {
  SupabaseMarketplaceRepository(
    this._db, {
    required this._trust,
    required this._wallet,
    required this._daily,
    required this._corridor,
  });

  final BackendGateway _db;
  final TrustRepository _trust;
  final WalletRepository Function() _wallet;
  final DailyCommuteRepository _daily;
  final Corridor _corridor;

  String get _me => _db.userId ?? (throw StateError('signed out'));

  // Row mapping ----------------------------------------------------------------------

  static Clock _clock(Object? s) {
    final parts = (s! as String).split(':');
    return Clock.hm(int.parse(parts[0]), int.parse(parts[1]));
  }

  static String _time(Clock c) => '${c.hour.toString().padLeft(2, '0')}:${c.minute.toString().padLeft(2, '0')}';

  static Stop _stop(Object? j) => Stop.fromJson((j! as Map).cast<String, Object?>());

  static OfferedTrip _offer(Row r) => OfferedTrip(
    id: r['id']! as String,
    driverId: r['driver_id']! as String,
    leg: Leg.values.byName(r['leg']! as String),
    from: Area.values.byName(r['origin_area']! as String),
    to: Area.values.byName(r['destination_area']! as String),
    date: CalendarDate.parse(r['trip_date']! as String),
    departure: _clock(r['departure']),
    durationMinutes: (r['duration_minutes'] as int?) ?? 40,
    seats: r['seats']! as int,
    riderSeats: r['rider_seats']! as int,
    tripCost: r['trip_cost']! as int,
    contribution: r['contribution']! as int,
    repeat: Repeat.values.byName(r['repeat']! as String),
    pickup: _stop(r['pickup']),
    status: OfferStatus.values.byName(r['status']! as String),
    groupId: r['group_id'] as String?,
    origin: OfferOrigin.values.byName((r['origin'] as String?) ?? OfferOrigin.published.name),
    cancelledWithRiders: (r['cancelled_with_riders'] as bool?) ?? false,
  );

  TripRequest _request(Row r) {
    final contribution = r['contribution']! as int;
    final fee = (r['fee'] as int?) ?? 0;
    return TripRequest(
      id: r['id']! as String,
      riderId: r['rider_id']! as String,
      rider: const AnonymousRider(isWoman: false),
      leg: Leg.values.byName(r['leg']! as String),
      from: Area.values.byName(r['origin_area']! as String),
      to: Area.values.byName(r['destination_area']! as String),
      date: CalendarDate.parse(r['trip_date']! as String),
      departure: _clock(r['departure']),
      repeat: Repeat.values.byName(r['repeat']! as String),
      pickup: _stop(r['pickup']),
      price: SeatPrice(
        contribution: contribution,
        share: contribution,
        fee: fee,
        mode: fee > 0 ? PricingMode.perTrip : PricingMode.trial,
      ),
      status: RequestStatus.values.byName(r['status']! as String),
      acceptedBy: r['accepted_by'] as String?,
      tripId: r['trip_ref'] as String?,
    );
  }

  static Booking _booking(Row r) {
    final contribution = r['contribution']! as int;
    final fee = (r['fee'] as int?) ?? 0;
    return Booking(
      id: r['id']! as String,
      riderId: r['rider_id']! as String,
      riderName: '',
      rider: const AnonymousRider(isWoman: false),
      source: BookingSource.offer(r['offered_trip_id']! as String),
      date: CalendarDate.parse(r['trip_date']! as String),
      leg: Leg.values.byName(r['leg']! as String),
      rideId: r['ride_id']! as String,
      price: SeatPrice(
        contribution: contribution,
        share: contribution,
        fee: fee,
        mode: fee > 0 ? PricingMode.perTrip : PricingMode.trial,
      ),
      paidBy: PaidBy.values.byName(r['paid_by']! as String),
      paid: (r['paid'] as int?) ?? 0,
      bookedAt: WallTime.of(DateTime.parse(r['booked_at']! as String).toLocal()),
      isSubscriber: (r['is_subscriber'] as bool?) ?? false,
      status: BookingStatus.values.byName(r['status']! as String),
    );
  }

  /// open|full → departed → done follow the clock, as in the fake.
  static OfferedTrip _onClock(OfferedTrip o, WallTime now) {
    if (o.status != OfferStatus.open && o.status != OfferStatus.full) return o;
    final start = WallTime(o.date, o.departure);
    if (now.isBefore(start)) return o;
    return o.copyWith(
      status: now.isBefore(start.plusMinutes(o.durationMinutes)) ? OfferStatus.departed : OfferStatus.done,
    );
  }

  // The rider's side of the gate (009 FR-008 order) ---------------------------------------

  Future<({BookingCheck check, PricingMode mode, PaymentMethod method})> _gate(WallTime now) async {
    final wallet = _wallet();
    final data = await wallet.getWallet(_me);
    final plan = await wallet.getPlan(_me);
    final covered = plan != null && plan.coversTrip(now);
    final mode = PricingMode.of(plan: plan, now: now, trialAvailable: data.cashTrial?.available ?? false);
    final check = BookingGate.check(
      hasArrangement: data.method != null || covered,
      openShares: data.shares,
      feeOverdue: data.feeOverdue ? data.owed : 0,
      idOk: (await _trust.riderIdStatus()).ok,
    );
    return (check: check, mode: mode, method: data.method ?? PaymentMethod.cash);
  }

  // A — Empty seats ------------------------------------------------------------------

  /// Offer rows with the driver's first name, rating and initials and the taken
  /// count (`market_offer_cards`); [ids] asks for those offers, booked ones too.
  Future<List<Row>> _cards([List<String>? ids]) async {
    final raw = (await _db.rpc('market_offer_cards', {'p_ids': ?ids})) as List? ?? const [];
    return [for (final m in raw.cast<Map<Object?, Object?>>()) m.cast<String, Object?>()];
  }

  static SeatDriver _driver(Row r) => SeatDriver(
    id: r['driver_id']! as String,
    firstName: (r['driver_first_name'] as String?) ?? '',
    initials: (r['driver_initials'] as String?) ?? '',
    rating: (r['driver_rating'] as num?)?.toDouble() ?? 0,
    isWoman: (r['driver_is_woman'] as bool?) ?? false,
  );

  @override
  Future<List<SeatOffer>> seatOffers(Leg leg, {required WallTime now}) async {
    final gate = await _gate(now);
    final out = <SeatOffer>[];
    for (final r in await _cards()) {
      if (r['leg'] != leg.name) continue;
      final o = _offer(r);
      if (o.driverId == _db.userId || !now.isBefore(WallTime(o.date, o.departure))) continue;
      final taken = r['taken']! as int;
      if (taken >= o.seats) continue;
      out.add(
        SeatOffer(
          source: BookingSource.offer(o.id),
          driver: _driver(r),
          pickup: o.pickup,
          date: o.date,
          leg: o.leg,
          departure: o.departure,
          freeSeats: o.seats - taken,
          price: SeatPrice.of(
            o.contribution,
            tripCost: o.tripCost,
            riderSeats: o.riderSeats,
            mode: gate.mode,
            method: gate.method,
          ),
          from: o.from,
          to: o.to,
          arrival: o.departure.shift(o.durationMinutes),
        ),
      );
    }
    out.sort((a, b) => a.departure.compareTo(b.departure));
    return out;
  }

  @override
  Future<BookResult> book(SeatOffer offer, {required WallTime now}) async {
    if (offer.source.kind != BookingSourceKind.offer) return const SeatTaken();
    final gate = await _gate(now);
    switch (gate.check.kind) {
      case BookingCheckKind.owesDriver:
        return BookOwesDriver(gate.check.amount, gate.check.driverFirstName);
      case BookingCheckKind.feeOverdue:
        return BookFeeOverdue(gate.check.amount);
      case BookingCheckKind.needsId:
        return const BookNeedsId();
      case BookingCheckKind.needsMethod:
        return const BookNeedsMethod();
      case BookingCheckKind.ok:
        break;
    }
    final paidBy = gate.mode.isFeeFree ? PaidBy.plan : PaidBy.wallet;
    try {
      final id =
          await _db.rpc('market_book', {
                'p_offer': offer.source.id,
                'p_contribution': offer.price.contribution,
                'p_fee': offer.price.fee,
                'p_paid_by': paidBy.name,
              })
              as String;
      final rows = await _db.select('bookings', where: [Filter.eq('id', id)]);
      return Booked(_booking(rows.single));
    } on BackendRefused catch (e) {
      // The server's own overdue backstop (013 D5), when the device gate was out of date.
      if (e.reason == 'feeOverdue') return BookFeeOverdue(int.tryParse(e.detail ?? '') ?? 0);
      return e.reason == 'alreadyRiding' ? const AlreadyRiding() : const SeatTaken();
    }
  }

  @override
  Future<CancelResult> cancelBooking(String bookingId, {required WallTime now}) async {
    try {
      return BookingCancelled((await _db.rpc('market_cancel_booking', {'p_booking': bookingId}))! as int);
    } on BackendRefused {
      return const NotCancellable();
    }
  }

  @override
  Future<List<Booking>> myBookings({required WallTime now}) async => [
    for (final r in await _db.select(
      'bookings',
      where: [Filter.eq('rider_id', _me), Filter.eq('status', BookingStatus.booked.name)],
      orderBy: 'trip_date',
    ))
      _booking(r),
  ];

  @override
  Future<SeatOffer?> seatOf(Booking booking) async {
    if (booking.source.kind != BookingSourceKind.offer) return null;
    final rows = await _cards([booking.source.id]);
    if (rows.isEmpty) return null;
    final o = _offer(rows.single);
    return SeatOffer(
      source: booking.source,
      driver: _driver(rows.single),
      pickup: o.pickup,
      date: o.date,
      leg: o.leg,
      departure: o.departure,
      freeSeats: 0,
      price: booking.price,
      from: o.from,
      to: o.to,
      arrival: o.departure.shift(o.durationMinutes),
    );
  }

  // B — Post your trip ----------------------------------------------------------------

  @override
  Future<PostResult> post(TripDraft draft, {required WallTime now}) async {
    if (draft.repeat == Repeat.daily && await _daily.myGroup() != null) return const DailyNotAllowed();
    final gate = await _gate(now);
    switch (gate.check.kind) {
      case BookingCheckKind.owesDriver:
        return PostOwesDriver(gate.check.amount, gate.check.driverFirstName);
      case BookingCheckKind.feeOverdue:
        return PostFeeOverdue(gate.check.amount);
      case BookingCheckKind.needsId:
        return const PostNeedsId();
      case BookingCheckKind.needsMethod:
        return const PostNeedsMethod();
      case BookingCheckKind.ok:
        break;
    }
    // The corridor's standard 3 seats' suggested contribution, fixed from now on (005 R6).
    final price = SeatPrice.of(
      PricingService.range(_corridor.tripCost, _corridor.riderSeats).suggested,
      tripCost: _corridor.tripCost,
      riderSeats: _corridor.riderSeats,
      mode: gate.mode,
      method: gate.method,
    );
    final date = MarketDay.nextWorkday(draft.departure, now);
    try {
      final id =
          await _db.rpc('market_post', {
                'p_leg': draft.leg.name,
                'p_origin': draft.from.name,
                'p_destination': draft.to.name,
                'p_date': date.toIso(),
                'p_departure': _time(draft.departure),
                'p_repeat': draft.repeat.name,
                'p_pickup': MarketSeed.pickupIn(draft.from, 'rq-stop-${now.toJson()}', draft.departure).toJson(),
                'p_contribution': price.contribution,
                'p_fee': price.fee,
              })
              as String;
      return Posted((await request(id, now: now))!);
    } on BackendRefused catch (e) {
      if (e.reason == 'dailyNotAllowed') return const DailyNotAllowed();
      if (e.reason == 'feeOverdue') return PostFeeOverdue(int.tryParse(e.detail ?? '') ?? 0);
      rethrow;
    }
  }

  @override
  Future<void> cancelRequest(String requestId) => _db.rpc('market_cancel_request', {'p_request': requestId});

  @override
  Future<List<TripRequest>> myRequests({required WallTime now}) async {
    final rows = await _db.select(
      'trip_requests',
      where: [Filter.eq('rider_id', _me), Filter.eq('status', RequestStatus.posted.name)],
    );
    final live =
        [
          for (final r in rows.map(_request))
            if (!MarketDay.isExpired(r.date, r.departure, now)) r,
        ]..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          if (byDate != 0) return byDate;
          final byTime = a.departure.compareTo(b.departure);
          return byTime != 0 ? byTime : a.id.compareTo(b.id);
        });
    return live;
  }

  /// A posted request past its departure reads as expired (not written back:
  /// the rider's row is only changed through `market_*`).
  @override
  Future<TripRequest?> request(String requestId, {required WallTime now}) async {
    final rows = await _db.select('trip_requests', where: [Filter.eq('id', requestId)]);
    if (rows.isEmpty) return null;
    final r = _request(rows.single);
    return r.status == RequestStatus.posted && MarketDay.isExpired(r.date, r.departure, now)
        ? r.copyWith(status: RequestStatus.expired)
        : r;
  }

  @override
  Future<int> driversOnRoute(TripDraft draft) async {
    final rows = await _db.select(
      'offered_trips',
      where: [
        Filter.eq('origin_area', draft.from.name),
        Filter.eq('destination_area', draft.to.name),
        Filter.eq('status', OfferStatus.open.name),
      ],
    );
    return {for (final r in rows) r['driver_id']}.length;
  }

  // C — Offer a trip -------------------------------------------------------------------

  @override
  Future<PublishResult> publish(OfferDraft draft, {required WallTime now}) async {
    final profile = await _trust.profile();
    final missing = [
      for (final item in profile.items)
        if (publishChecks.contains(item.kind) && item.status != VerificationStatus.verified) item.kind,
    ];
    if (missing.isNotEmpty) return NotVerified(missing);

    final range = PricingService.range(_corridor.tripCost, draft.seats);
    if (!range.contains(draft.contribution)) {
      throw ArgumentError.value(draft.contribution, 'contribution', 'outside ${range.min}–${range.max} EGP');
    }

    final date = MarketDay.nextWorkday(draft.departure, now);
    final day = await driverDay(date);
    final minutes = _corridor.tripMinutes(draft.from, draft.to);
    final fit = DriverDayRules.fit(
      day.trips,
      Candidate(
        leg: draft.leg,
        from: draft.from,
        to: draft.to,
        departure: draft.departure.minutes,
        durationMinutes: minutes,
        daily: draft.repeat == Repeat.daily,
        leadsGroup: day.leadsGroup,
      ),
    );
    if (fit.kind != TripFitKind.create) return OverLimit(fit);

    try {
      final id =
          await _db.rpc('market_publish', {
                'p_leg': draft.leg.name,
                'p_origin': draft.from.name,
                'p_destination': draft.to.name,
                'p_date': date.toIso(),
                'p_departure': _time(draft.departure),
                'p_seats': draft.seats,
                'p_trip_cost': _corridor.tripCost,
                'p_contribution': draft.contribution,
                'p_repeat': draft.repeat.name,
                'p_pickup': MarketSeed.pickupIn(draft.from, 'of-stop-${now.toJson()}', draft.departure).toJson(),
              })
              as String;
      return Published((await offer(id, now: now))!);
    } on BackendRefused catch (e) {
      return switch (e.reason) {
        'overLimit' => const OverLimit(TripFit.limitReached()),
        'notVerified' => const NotVerified([VerificationKind.license, VerificationKind.vehicle]),
        _ => throw e,
      };
    }
  }

  @override
  Future<OfferedTrip?> offer(String tripId, {required WallTime now}) async {
    final rows = await _db.select('offered_trips', where: [Filter.eq('id', tripId)]);
    return rows.isEmpty ? null : _onClock(_offer(rows.single), now);
  }

  /// No rider names before departure, and none from the server yet (R15).
  @override
  Future<OfferLive> live(String tripId, {required WallTime now}) async {
    final trip = await offer(tripId, now: now) ?? (throw StateError('no offer $tripId'));
    final rows = await _db.select(
      'bookings',
      where: [
        Filter.eq('offered_trip_id', tripId),
        Filter.inList('status', [BookingStatus.booked.name, BookingStatus.done.name]),
      ],
      orderBy: 'booked_at',
    );
    return OfferLive(
      trip: trip,
      riders: [
        for (final b in rows.map(_booking))
          LiveRider(rider: b.rider, riderId: b.riderId, paidBy: b.paidBy, price: b.price),
      ],
    );
  }

  @override
  Future<void> cancelOffer(String tripId, {required WallTime now}) async {
    final o = await offer(tripId, now: now);
    if (o == null || (o.status != OfferStatus.open && o.status != OfferStatus.full)) return;
    await _db.rpc('market_cancel_offer', {'p_trip': tripId});
  }

  // D — Find riders / driver Today -------------------------------------------------------

  @override
  Future<DriverDay> driverDay(CalendarDate date) async {
    final group = await _daily.myGroup();
    final rows = await _db.select(
      'offered_trips',
      where: [Filter.eq('driver_id', _me), Filter.eq('trip_date', date.toIso())],
    );
    final trips = <DayTrip>[];

    // The group legs the person actually drives (the schedule's actual driver), as the fake
    // does. No group-seat bookings exist on the server, so no seats are held.
    if (group != null) {
      final day = (await _daily.schedule(date, date)).where((d) => d.date == date).firstOrNull;
      for (final leg in Leg.values) {
        if (day?.assignment(leg)?.actual != _me) continue;
        final ride = await _daily.ride(date, leg);
        if (ride == null) continue;
        final free = SeatMath.ownGroupLeg(ride, riderSeats: group.riderSeats);
        final going = leg == Leg.going;
        trips.add(
          DayTrip(
            id: Ride.idFor(group.id, date, leg),
            leg: leg,
            from: going ? group.origin : group.destination,
            to: going ? group.destination : group.origin,
            departure: group.timeFor(leg).minutes,
            durationMinutes: group.tripMinutes,
            seats: group.riderSeats,
            taken: group.riderSeats - free,
          ),
        );
      }
    }

    for (final o in rows.map(_offer)) {
      if (o.status == OfferStatus.grouped) continue;
      if (o.status == OfferStatus.cancelled && !o.cancelledWithRiders) continue;
      final taken = o.status == OfferStatus.cancelled
          ? o.seats
          : (await _db.select(
              'bookings',
              where: [
                Filter.eq('offered_trip_id', o.id),
                Filter.inList('status', [BookingStatus.booked.name, BookingStatus.done.name]),
              ],
            )).length;
      trips.add(
        DayTrip(
          id: o.id,
          leg: o.leg,
          from: o.from,
          to: o.to,
          departure: o.departure.minutes,
          durationMinutes: o.durationMinutes,
          seats: o.seats,
          taken: taken,
        ),
      );
    }
    trips.sort((a, b) {
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return DriverDay(date: date, trips: trips, leadsGroup: group?.member(_me)?.role == MemberRole.driver);
  }

  /// Posted requests of other riders (`market_requests_for`: no rider id, name or home),
  /// then the driver's own privacy choice and the day's fit, with the fake's rules.
  Future<List<RequestCard>> _requestCards(Leg wanted, Area? leavingFrom, WallTime now) async {
    final raw = (await _db.rpc('market_requests_for', {'p_leg': wanted.name})) as List? ?? const [];
    final profile = await _trust.profile();
    final days = <CalendarDate, DriverDay>{};
    final cards = <RequestCard>[];
    for (final r in raw.cast<Map<Object?, Object?>>().map((m) => m.cast<String, Object?>())) {
      final date = CalendarDate.parse(r['trip_date']! as String);
      final departure = _clock(r['departure']);
      if (MarketDay.isExpired(date, departure, now)) continue;
      final isWoman = (r['rider_is_woman'] as bool?) ?? false;
      if (!PrivacyRules.accepts(profile.privacy, profile.facts, PersonFacts(isWoman: isWoman))) continue;
      final from = Area.values.byName(r['origin_area']! as String);
      final to = Area.values.byName(r['destination_area']! as String);
      final repeat = Repeat.values.byName(r['repeat']! as String);
      final contribution = r['contribution']! as int;
      final fee = (r['fee'] as int?) ?? 0;
      // The fake's heuristic: 3 minutes from the rider's own area, 6 from anywhere else.
      final detour = leavingFrom == null || leavingFrom == from ? 3 : 6;
      final day = days[date] ??= await driverDay(date);
      final fit = DriverDayRules.fit(
        day.trips,
        Candidate(
          leg: wanted,
          from: from,
          to: to,
          departure: departure.minutes,
          durationMinutes: _corridor.tripMinutes(from, to),
          daily: repeat == Repeat.daily,
          leadsGroup: day.leadsGroup,
        ),
      );
      cards.add(
        RequestCard(
          requestId: r['id']! as String,
          leg: wanted,
          from: from,
          to: to,
          rider: AnonymousRider(isWoman: isWoman),
          pickup: _stop(r['pickup']),
          date: date,
          departure: departure,
          repeat: repeat,
          price: SeatPrice(
            contribution: contribution,
            share: contribution,
            fee: fee,
            mode: fee > 0 ? PricingMode.perTrip : PricingMode.trial,
          ),
          detourMinutes: detour,
          fit: fit,
          joinTime: fit.kind == TripFitKind.join
              ? Clock(day.trips.firstWhere((t) => t.id == fit.tripId).departure)
              : null,
        ),
      );
    }
    cards.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      final byTime = a.departure.compareTo(b.departure);
      return byTime != 0 ? byTime : a.requestId.compareTo(b.requestId);
    });
    return cards;
  }

  @override
  Future<List<RequestCard>> requestsForMe({Area? leavingFrom, required PartOfDay part, required WallTime now}) =>
      _requestCards(part == PartOfDay.morning ? Leg.going : Leg.ret, leavingFrom, now);

  /// A driver cannot read another rider's request row, so the request is found among the
  /// cards the server offers. Joining a trip the driver already has is not on the server
  /// yet (013 research, re-filed): such a request is refused here rather than adding a trip.
  @override
  Future<AcceptResult> accept(String requestId, {required WallTime now}) async {
    for (final leg in Leg.values) {
      final card = (await _requestCards(leg, null, now)).where((c) => c.requestId == requestId).firstOrNull;
      if (card == null) continue;
      if (card.fit.kind != TripFitKind.create) return AcceptRefused(card.fit);
      try {
        final tripId = (await _db.rpc('market_accept', {
          'p_request': requestId,
          'p_trip_cost': _corridor.tripCost,
          'p_seats': _corridor.riderSeats,
        }))! as String;
        final trip = (await _db.select('offered_trips', where: [Filter.eq('id', tripId)])).single;
        return AcceptCreated((await driverDay(CalendarDate.parse(trip['trip_date']! as String))).tripsLeft);
      } on BackendRefused catch (e) {
        // `feeOverdue` has no result of its own on this seam: the request just can't be taken.
        return AcceptRefused(e.reason == 'overLimit' ? const TripFit.limitReached() : const TripFit.doesntFit());
      }
    }
    return const AcceptRefused(TripFit.doesntFit());
  }

  /// A subscriber takes the seat (005 US6): the server applies the fake's rules.
  @override
  Future<ReclaimResult> reclaim(String bookingId, {required WallTime now}) async {
    try {
      return Reclaimed((await _db.rpc('market_reclaim', {'p_booking': bookingId}))! as int);
    } on BackendRefused catch (e) {
      return e.reason == 'reclaimTooLate' ? const ReclaimTooLate() : const NotReclaimable();
    }
  }

  @override
  Future<List<DoneOneOff>> doneOneOffs() async {
    final raw = (await _db.rpc('market_done_one_offs')) as List? ?? const [];
    return [
      for (final r in raw.cast<Map<Object?, Object?>>().map((m) => m.cast<String, Object?>()))
        DoneOneOff(
          rideId: r['ride_id']! as String,
          date: CalendarDate.parse(r['trip_date']! as String),
          leg: Leg.values.byName(r['leg']! as String),
          paidBy: PaidBy.values.byName(r['paid_by']! as String),
          contribution: r['contribution']! as int,
          tripCost: r['trip_cost']! as int,
          riderSeats: r['rider_seats']! as int,
          riderId: r['rider_id']! as String,
          driverId: r['driver_id']! as String,
          riderName: (r['rider_first_name'] as String?) ?? '',
          driverName: (r['driver_first_name'] as String?) ?? '',
          end: WallTime.fromJson(r['trip_end']! as String),
        ),
    ];
  }

  // Demo (debug only): nothing to act on against a real server ---------------------------

  @override
  Future<DemoResult> demoDriverAccepts({required WallTime now}) async => const DemoNothing();

  @override
  Future<DemoResult> demoRiderBooks({required WallTime now}) async => const DemoNothing();

  @override
  Future<DemoResult> demoSubscriberTakes({required WallTime now}) async => const DemoNothing();
}
