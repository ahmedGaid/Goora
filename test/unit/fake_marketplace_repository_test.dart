import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';
import 'package:goora/features/daily/data/daily_seed.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/daily/domain/privacy.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/driver_day_rules.dart';
import 'package:goora/features/marketplace/domain/market_day.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/domain/seat_offer.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/activity_entry.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 005 T041 (seed) and T043 (driver day, R5) on the real fakes — no mocks.

/// Tue 6 Oct 2026 is a ride day of sz-0725 (rotation start Sun 4 Oct); Thu 8
/// Oct is the person's turn to drive when they join as a driver.
final _tue = rideTuesday;
final _thu = _tue.addDays(2);

final class _World {
  _World(this.repo, this.daily, this.prefs, this.clock, this.wallet, this.trust, this._pay);

  final FakeMarketplaceRepository repo;
  final FakeDailyCommuteRepository daily;
  final SharedPreferences prefs;
  final TestClock clock;
  final FakeWalletRepository wallet;
  final FakeTrustRepository trust;
  final _PayFlag _pay;

  /// The next payment (top-up or debit) fails.
  set payFails(bool v) => _pay.fails = v;

  Future<int> balance() async => (await wallet.getWallet('me')).balance;
  Future<List<ActivityEntry>> activity() async => (await wallet.getWallet('me')).activity;
}

final class _PayFlag {
  bool fails = false;
}

Future<_World> _make({
  Role role = Role.driver,
  bool member = true,
  Map<String, Object> extra = const {},
  WallTime? start,
  Gender gender = Gender.male,
  bool withPlan = true,
  PaymentMethod? method,
}) async {
  SharedPreferences.setMockInitialValues({
    ...memberPrefs(role: role, member: member, gender: gender, withPlan: withPlan, method: method),
    ...extra,
  });
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(start ?? at(_tue, 20, 0));
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: gender, role: role);
  final pay = _PayFlag();
  final catalog = GroupCatalog(prefs);
  final daily = FakeDailyCommuteRepository(
    prefs,
    commute: FakeCommuteRepository(prefs, catalog: catalog),
    person: () => person,
    now: clock.call,
    catalog: catalog,
  );
  final wallet = FakeWalletRepository(
    prefs,
    daily: daily,
    role: () => role == Role.driver ? MemberRole.driver : MemberRole.rider,
    now: clock.call,
    provider: FakePaymentProvider(shouldFail: () => pay.fails),
  );
  final trust = FakeTrustRepository(prefs, person: () => person, now: clock.call);
  final repo = FakeMarketplaceRepository(
    prefs,
    catalog: catalog,
    daily: daily,
    commute: FakeCommuteRepository(prefs, catalog: catalog),
    notices: daily,
    ledger: () => wallet,
    wallet: () => wallet,
    trust: trust,
    now: clock.call,
  );
  return _World(repo, daily, prefs, clock, wallet, trust, pay);
}

OfferedTrip _offer(
  String id, {
  required CalendarDate date,
  Leg leg = Leg.going,
  Clock departure = const Clock.hm(9, 0),
  OfferStatus status = OfferStatus.open,
  bool cancelledWithRiders = false,
  String driverId = 'me',
  int seats = 3,
  Area? from,
}) => OfferedTrip(
  id: id,
  driverId: driverId,
  leg: leg,
  from: from ?? (leg == Leg.going ? Area.sheikhZayed : Area.smartVillage),
  to: leg == Leg.going ? Area.smartVillage : Area.sheikhZayed,
  date: date,
  departure: departure,
  seats: seats,
  riderSeats: 3,
  tripCost: MarketSeed.tripCost,
  contribution: 40,
  repeat: Repeat.once,
  pickup: MarketSeed.offers(WallTime(date, departure)).first.pickup,
  status: status,
  cancelledWithRiders: cancelledWithRiders,
);

Booking _booking(
  String id, {
  required BookingSource source,
  required CalendarDate date,
  Leg leg = Leg.going,
  String? rideId,
  BookingStatus status = BookingStatus.booked,
  PaidBy paidBy = PaidBy.wallet,
  String riderId = 'seed-rider-nadia',
  WallTime? bookedAt,
}) => Booking(
  id: id,
  riderId: riderId,
  riderName: 'Nadia',
  rider: const AnonymousRider(isWoman: true, rating: 4.6),
  source: source,
  date: date,
  leg: leg,
  rideId: rideId ?? Booking.offerRideId(source.id),
  price: MarketSeed.quote(40),
  paidBy: paidBy,
  paid: paidBy == PaidBy.cash ? 0 : 44,
  bookedAt: bookedAt ?? at(date.addDays(-2), 12, 0),
  isSubscriber: false,
  status: status,
);

Map<String, Object> _stored(String key, List<Map<String, Object?>> items) => {key: jsonEncode(items)};

void main() {
  group('MarketSeed (T041, R14)', () {
    final now = at(_tue, 6, 0);

    test('12 open morning requests, 7:00–8:00, and 4 evening ones', () {
      final all = MarketSeed.requests(now);
      final morning = all.where((r) => r.leg == Leg.going).toList();
      final evening = all.where((r) => r.leg == Leg.ret).toList();
      expect(morning, hasLength(12));
      expect(evening, hasLength(4));
      expect(morning.map((r) => r.departure.minutes), everyElement(inInclusiveRange(7 * 60, 8 * 60)));
      expect(all.map((r) => r.id).toSet(), hasLength(16), reason: 'ids are unique');
      expect(all.map((r) => r.status).toSet(), {RequestStatus.posted});
      expect(morning.map((r) => r.from).toSet(), {Area.sheikhZayed});
      expect(morning.map((r) => r.to).toSet(), {Area.smartVillage});
    });

    test('mixed riders: women and men, once and daily, rated and New', () {
      final morning = MarketSeed.requests(now).where((r) => r.leg == Leg.going);
      expect(morning.map((r) => r.rider.isWoman).toSet(), {true, false});
      expect(morning.map((r) => r.repeat).toSet(), {Repeat.once, Repeat.daily});
      expect(morning.map((r) => r.rider.rating == null).toSet(), {true, false});
    });

    test('every Sheikh Zayed driver fits all 12 (detour under 10); fewer from October', () {
      final morning = MarketSeed.requests(now).where((r) => r.leg == Leg.going).toList();
      expect(morning.where((r) => r.detourFrom[Area.sheikhZayed]! < 10), hasLength(12));
      final october = morning.where((r) => r.detourFrom[Area.october]! < 10).length;
      expect(october, inInclusiveRange(1, 11));
    });

    test('a request is dated its next workday and never in the past', () {
      for (final r in MarketSeed.requests(at(CalendarDate(2026, 10, 9), 12, 0))) {
        // Friday midday: the next running day is Sunday.
        expect(r.date, CalendarDate(2026, 10, 11));
      }
      for (final r in MarketSeed.requests(now)) {
        expect(MarketDay.isExpired(r.date, r.departure, now), isFalse, reason: r.id);
      }
    });

    test('request prices are fixed quotes inside the range, with the 10% fee', () {
      final r = MarketSeed.requests(now).first;
      expect(r.price.contribution, 40);
      expect(r.price.fee, 4);
      expect(r.price.total, 44);
      expect(r.price.cash, 40);
    });

    test("Tarek's 44 shows 48 for a wallet rider and 45 for a cash rider; Heba's 40 is daily", () {
      final tarek = MarketSeed.offers(now).firstWhere((o) => o.id == MarketSeed.tarekId);
      expect((tarek.repeat, tarek.leg, tarek.departure, tarek.seats, tarek.contribution), (
        Repeat.once,
        Leg.going,
        const Clock.hm(7, 30),
        3,
        44,
      ));
      final wallet = MarketSeed.quote(tarek.contribution);
      expect((wallet.fee, wallet.total, wallet.cash), (4, 48, 45));

      final heba = MarketSeed.offers(now).firstWhere((o) => o.id == MarketSeed.hebaId);
      expect((heba.repeat, heba.leg, heba.departure, heba.seats, heba.contribution), (
        Repeat.daily,
        Leg.ret,
        const Clock.hm(17, 10),
        3,
        40,
      ));
    });

    test('seeded offers sit inside the cost-share range and the 2 EGP step', () {
      for (final o in MarketSeed.offers(now)) {
        final range = PricingService.range(o.tripCost, o.riderSeats);
        expect(range.contains(o.contribution), isTrue, reason: o.id);
        expect(o.contribution % PricingService.step, 0, reason: o.id);
      }
    });

    test('the pools hold named fake drivers and riders; the offers belong to pool drivers', () {
      expect(MarketSeed.drivers, hasLength(greaterThanOrEqualTo(3)));
      expect(MarketSeed.riders, hasLength(greaterThanOrEqualTo(3)));
      for (final o in MarketSeed.offers(now)) {
        expect(MarketSeed.driverById(o.driverId), isNotNull, reason: o.id);
      }
    });
  });

  group('driverDay (T043, R5)', () {
    test("a group leg the person drives counts, with the group's route, time and seats", () async {
      final w = await _make();
      final day = await w.repo.driverDay(_thu);
      final ride = (await w.daily.ride(_thu, Leg.going))!;
      expect(ride.driverId, 'me');

      final trip = day.trips.firstWhere((t) => t.id == Ride.idFor('sz-0725', _thu, Leg.going));
      expect((trip.leg, trip.from, trip.to), (Leg.going, Area.sheikhZayed, Area.smartVillage));
      expect(trip.departure, const Clock.hm(7, 25).minutes);
      expect(trip.seats, 3);
      // Seats are the price basis (R6): sz-0725 carries 4 (2 riders + 2 off-duty drivers) against 3.
      expect(ride.passengers.length, 4);
      expect(trip.taken, 3, reason: 'riders and off-duty drivers, capped at the basis; the trip is full');
      expect(day.tripsLeft, 2 - day.trips.length);
    });

    test('only the legs the person actually drives are listed', () async {
      final w = await _make();
      final mine = {
        for (final leg in Leg.values)
          if ((await w.daily.ride(_thu, leg))?.driverId == 'me') leg,
      };
      expect(mine, isNotEmpty);
      expect((await w.repo.driverDay(_thu)).trips.map((t) => t.leg).toSet(), mine);
    });

    test("a leg a backup covers doesn't count", () async {
      final w = await _make(start: at(_thu.addDays(-1), 20, 0));
      expect((await w.repo.driverDay(_thu)).trips.map((t) => t.leg), contains(Leg.going));

      final result = await w.daily.cantDrive(_thu, {Leg.going}, at(_thu.addDays(-1), 20, 0));
      expect(result.found, isTrue);
      expect((await w.daily.ride(_thu, Leg.going))!.driverId, isNot('me'));

      final trips = (await w.repo.driverDay(_thu)).trips;
      expect(trips.where((t) => t.leg == Leg.going), isEmpty);
    });

    test("a day the person doesn't drive is empty and a rider has no day", () async {
      final w = await _make();
      // Wed 7 Oct is Ahmed's or Mohamed's turn on at least one leg of three drivers.
      final wed = _tue.addDays(1);
      for (final trip in (await w.repo.driverDay(wed)).trips) {
        expect((await w.daily.ride(wed, trip.leg))!.driverId, 'me');
      }
      final rider = await _make(role: Role.rider);
      final day = await rider.repo.driverDay(_thu);
      expect(day.trips, isEmpty);
      expect(day.leadsGroup, isFalse);
      expect(day.tripsLeft, 2);
    });

    test('a friday has no group trips', () async {
      final w = await _make();
      expect((await w.repo.driverDay(CalendarDate(2026, 10, 9))).trips, isEmpty);
    });

    test('leadsGroup is true for the driver of sz-0725, false for a rider or someone with no group', () async {
      expect((await (await _make()).repo.driverDay(_thu)).leadsGroup, isTrue);
      expect((await (await _make(role: Role.rider)).repo.driverDay(_thu)).leadsGroup, isFalse);
      expect((await (await _make(member: false)).repo.driverDay(_thu)).leadsGroup, isFalse);
    });

    test('an offered trip that is open, full or done counts, with its bookings as taken', () async {
      final w = await _make(
        member: false,
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [
            _offer('of-1', date: _thu).toJson(),
            _offer('of-2', date: _thu, leg: Leg.ret, departure: const Clock.hm(17, 0), seats: 1).toJson(),
          ]),
          ..._stored(FakeMarketplaceRepository.bookingsKey, [
            _booking('bk-1', source: const BookingSource.offer('of-1'), date: _thu).toJson(),
            _booking('bk-2', source: const BookingSource.offer('of-1'), date: _thu, riderId: 'r2').toJson(),
            _booking('bk-3', source: const BookingSource.offer('of-2'), date: _thu, riderId: 'r3').toJson(),
          ]),
        },
      );
      final day = await w.repo.driverDay(_thu);
      expect(day.trips.map((t) => t.id), ['of-1', 'of-2']);
      expect(day.trips.map((t) => t.taken), [2, 1]);
      expect(day.tripsLeft, 0);
    });

    test('a cancelled offer with no bookings is dropped; with a booking it counts (R5)', () async {
      final empty = await _make(
        member: false,
        extra: _stored(FakeMarketplaceRepository.offersKey, [
          _offer('of-1', date: _thu, status: OfferStatus.cancelled).toJson(),
        ]),
      );
      final dropped = await empty.repo.driverDay(_thu);
      expect(dropped.trips, isEmpty);
      expect(dropped.tripsLeft, 2);

      final withRider = await _make(
        member: false,
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [
            _offer('of-1', date: _thu, status: OfferStatus.cancelled, cancelledWithRiders: true).toJson(),
          ]),
          ..._stored(FakeMarketplaceRepository.bookingsKey, [
            _booking('bk-1', source: const BookingSource.offer('of-1'), date: _thu, status: BookingStatus.refunded)
                .toJson(),
          ]),
        },
      );
      final counted = await withRider.repo.driverDay(_thu);
      expect(counted.trips.map((t) => t.id), ['of-1']);
      expect(counted.tripsLeft, 1);
      expect(counted.trips.single.taken, counted.trips.single.seats, reason: 'not a trip a request can join');
    });

    test("another driver's offers, other days and a grouped daily offer are not on the day", () async {
      final w = await _make(
        member: false,
        extra: _stored(FakeMarketplaceRepository.offersKey, [
          _offer('of-theirs', date: _thu, driverId: 'tarek').toJson(),
          _offer('of-other-day', date: _thu.addDays(1)).toJson(),
          _offer('of-grouped', date: _thu, status: OfferStatus.grouped).toJson(),
        ]),
      );
      expect((await w.repo.driverDay(_thu)).trips, isEmpty);
    });

    test('a seeded offer owned by a seeded driver never lands on the person\'s day', () async {
      final w = await _make(member: false);
      final seeded = MarketSeed.offers(w.clock.now).first;
      expect((await w.repo.driverDay(seeded.date)).trips, isEmpty);
    });
  });

  group('doneOneOffs (T038 seam)', () {
    final dayAfter = _thu.addDays(1);

    test('a booked seat counts once the trip has ended, not before', () async {
      final w = await _make(
        member: false,
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [_offer('of-1', date: _thu).toJson()]),
          ..._stored(FakeMarketplaceRepository.bookingsKey, [
            _booking('bk-1', source: const BookingSource.offer('of-1'), date: _thu).toJson(),
          ]),
        },
        start: at(_thu, 9, 30),
      );
      expect(await w.repo.doneOneOffs(), isEmpty, reason: 'departed 9:00, ends 9:40');

      w.clock.now = at(_thu, 9, 40);
      final done = await w.repo.doneOneOffs();
      expect(done, hasLength(1));
      expect(done.single.rideId, 'offer:of-1');
      expect((done.single.contribution, done.single.tripCost, done.single.riderSeats), (40, 160, 3));
      expect((done.single.riderId, done.single.driverId), ('seed-rider-nadia', 'me'));
      expect(done.single.paidBy, PaidBy.wallet);
    });

    test('cancelled, reclaimed and refunded seats never count; cash ones do', () async {
      final w = await _make(
        member: false,
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [_offer('of-1', date: _thu).toJson()]),
          ..._stored(FakeMarketplaceRepository.bookingsKey, [
            for (final (i, s) in [BookingStatus.cancelled, BookingStatus.reclaimed, BookingStatus.refunded].indexed)
              _booking('bk-$i', source: const BookingSource.offer('of-1'), date: _thu, status: s).toJson(),
            _booking('bk-cash', source: const BookingSource.offer('of-1'), date: _thu, paidBy: PaidBy.cash).toJson(),
          ]),
        },
        start: at(dayAfter, 8, 0),
      );
      final done = await w.repo.doneOneOffs();
      expect(done.map((d) => d.paidBy), [PaidBy.cash]);
    });

    test('a seat on a group leg uses the group basis and its driver', () async {
      final w = await _make(
        role: Role.rider,
        extra: _stored(FakeMarketplaceRepository.bookingsKey, [
          _booking(
            'bk-g',
            source: const BookingSource.groupSeat('sz-0725'),
            date: _thu,
            rideId: Ride.idFor('sz-0725', _thu, Leg.going),
          ).toJson(),
        ]),
        start: at(dayAfter, 8, 0),
      );
      final done = (await w.repo.doneOneOffs()).single;
      expect((done.tripCost, done.riderSeats), (160, 3));
      expect(done.rideId, Ride.idFor('sz-0725', _thu, Leg.going));
      expect(['ahmed', 'mohamed'], contains(done.driverId), reason: 'a seeded driver of the group');
    });

    test('a seat from an accepted request resolves through the request to its trip', () async {
      final request = MarketSeed.requests(at(_thu, 6, 0)).first.copyWith(
        status: RequestStatus.accepted,
        acceptedBy: 'me',
        tripId: 'of-1',
      );
      final w = await _make(
        member: false,
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [_offer('of-1', date: _thu).toJson()]),
          ..._stored(FakeMarketplaceRepository.requestsKey, [request.toJson()]),
          ..._stored(FakeMarketplaceRepository.bookingsKey, [
            _booking('bk-r', source: BookingSource.request(request.id), date: _thu).toJson(),
          ]),
        },
        start: at(dayAfter, 8, 0),
      );
      expect((await w.repo.doneOneOffs()).map((d) => d.driverId), ['me']);
    });

    test('a booking whose trip is unknown is left out rather than guessed', () async {
      final w = await _make(
        member: false,
        extra: _stored(FakeMarketplaceRepository.bookingsKey, [
          _booking('bk-x', source: const BookingSource.offer('of-gone'), date: _thu).toJson(),
        ]),
        start: at(dayAfter, 8, 0),
      );
      expect(await w.repo.doneOneOffs(), isEmpty);
    });
  });

  group('storage overlay and reset (T042, T044)', () {
    test('a booking whose request has no trip yet stays unresolved', () async {
      final w = await _make(member: false);
      final taken = MarketSeed.requests(w.clock.now).first.copyWith(status: RequestStatus.accepted, acceptedBy: 'me');
      await w.prefs.setString(FakeMarketplaceRepository.requestsKey, jsonEncode([taken.toJson()]));

      await w.prefs.setString(FakeMarketplaceRepository.offersKey, jsonEncode([_offer('of-1', date: _thu).toJson()]));
      await w.prefs.setString(
        FakeMarketplaceRepository.bookingsKey,
        jsonEncode([_booking('bk', source: BookingSource.request(taken.id), date: _thu).toJson()]),
      );
      w.clock.now = at(_thu.addDays(1), 8, 0);
      expect(await w.repo.doneOneOffs(), isEmpty);
    });

    test('driverDay is stable across calls (no writes on read)', () async {
      final w = await _make();
      final before = w.prefs.getKeys().where((k) => k.startsWith('market.')).toSet();
      await w.repo.driverDay(_thu);
      await w.repo.driverDay(_thu);
      expect(w.prefs.getKeys().where((k) => k.startsWith('market.')).toSet(), before);
    });

    test('reset leaves no market.* key — offers, requests, bookings, cursor, groups and members', () async {
      final w = await _make(
        extra: {
          ..._stored(FakeMarketplaceRepository.offersKey, [_offer('of-1', date: _thu).toJson()]),
          ..._stored(FakeMarketplaceRepository.requestsKey, const []),
          ..._stored(FakeMarketplaceRepository.bookingsKey, const []),
          FakeMarketplaceRepository.seedCursorKey: 2,
          GroupCatalog.groupsKey: '[]',
          GroupCatalog.membersKey('sz-0725'): '[]',
          'wallet.plan': 'kept-by-another-reset',
        },
      );
      expect(w.prefs.getKeys().where((k) => k.startsWith('market.')), hasLength(6));

      await w.repo.clear();

      expect(w.prefs.getKeys().where((k) => k.startsWith('market.')), isEmpty);
      expect(w.prefs.containsKey('wallet.plan'), isTrue, reason: 'only the marketplace keys');
      expect(await w.repo.doneOneOffs(), isEmpty);
      final catalog = GroupCatalog(w.prefs);
      expect(catalog.all().every((g) => !g.id.startsWith(GroupCatalog.createdPrefix)), isTrue);
    });

    test('the payment method is untouched by the marketplace', () async {
      final w = await _make(role: Role.rider);
      await FakeWalletRepository(
        w.prefs,
        daily: w.daily,
        role: () => MemberRole.rider,
        now: w.clock.call,
        provider: FakePaymentProvider(),
      ).setMethod('me', PaymentMethod.cash);
      await w.repo.clear();
      expect(w.prefs.getString(FakeWalletRepository.methodKey('me')), isNotNull);
    });
  });

  group('Empty seats (T046, US1)', () {
    final wed = _tue.addDays(1);
    final thu = _tue.addDays(2);

    Map<String, Object> offers(List<OfferedTrip> trips) =>
        _stored(FakeMarketplaceRepository.offersKey, [for (final t in trips) t.toJson()]);
    Map<String, Object> bookings(List<Booking> items) =>
        _stored(FakeMarketplaceRepository.bookingsKey, [for (final b in items) b.toJson()]);

    /// A once rider on the corridor: no group, no plan.
    Future<_World> once({
      PaymentMethod? method = PaymentMethod.wallet,
      int balance = 0,
      Map<String, Object> extra = const {},
      WallTime? start,
      Gender gender = Gender.male,
      bool company = false,
    }) async {
      final w = await _make(
        role: Role.rider,
        member: false,
        method: method,
        gender: gender,
        start: start,
        extra: {
          if (company)
            FakeWalletRepository.planKey: jsonEncode(
              const Plan(personId: DailySeed.meId, type: PlanType.company, status: PlanStatus.active, price: 0)
                  .toJson(),
            ),
          ...extra,
        },
      );
      if (balance > 0) await w.wallet.topUp('me', method: 'card', amount: balance);
      return w;
    }

    SeatOffer fromOffer(List<SeatOffer> all, String tripId) =>
        all.firstWhere((o) => o.source == BookingSource.offer(tripId));

    Future<List<SeatOffer>> going(_World w) => w.repo.seatOffers(Leg.going, now: w.clock.now);

    group('seatOffers', () {
      test("prices follow the viewer: 48 wallet, 45 cash, fee-free company — Tarek's 44", () async {
        final wallet = await once();
        final a = fromOffer(await going(wallet), MarketSeed.tarekId);
        expect((a.price.contribution, a.price.fee, a.price.total), (44, 4, 48));
        expect(a.driver.firstName, 'Tarek');
        expect((a.leg, a.date, a.departure, a.freeSeats), (Leg.going, wed, const Clock.hm(7, 30), 3));

        final cash = await once(method: PaymentMethod.cash);
        final b = fromOffer(await going(cash), MarketSeed.tarekId);
        expect((b.price.cash, b.price.payable), (45, 45));

        final company = await once(method: null, company: true);
        final c = fromOffer(await going(company), MarketSeed.tarekId);
        expect((c.price.fee, c.price.total), (0, 44));
      });

      test('route fit: same from/to for the leg — another area and the other leg are left out', () async {
        final w = await once(extra: offers([_offer('of-oct', date: wed, driverId: 'khaled', from: Area.october)]));
        final out = await w.repo.seatOffers(Leg.going, now: w.clock.now);
        final ids = out.where((o) => o.source.kind == BookingSourceKind.offer).map((o) => o.source.id);
        expect(ids, [MarketSeed.tarekId]);

        final back = await w.repo.seatOffers(Leg.ret, now: w.clock.now);
        expect(back.every((o) => o.leg == Leg.ret), isTrue);
        expect(back.map((o) => o.source.id), contains(MarketSeed.hebaId));
        expect(back.map((o) => o.source.id), isNot(contains(MarketSeed.tarekId)));
      });

      test('a group seat is listed for a non-member with the group price, its free seat and a pickup', () async {
        final w = await once();
        final seat = (await going(w)).firstWhere((o) => o.source == const BookingSource.groupSeat('sz-0725'));
        expect(seat.freeSeats, 1);
        expect((seat.price.contribution, seat.price.total), (40, 44));
        expect(seat.date, wed);
      });

      test('women-only lists only women-driven cars and offers', () async {
        final w = await once(gender: Gender.female);
        await w.trust.setPrivacy(PrivacyPreference.womenOnly);
        final all = [...await going(w), ...await w.repo.seatOffers(Leg.ret, now: w.clock.now)];
        expect(all, isNotEmpty);
        expect(all.every((o) => o.driver.isWoman), isTrue);
        expect(all.map((o) => o.source.id), contains(MarketSeed.hebaId));
        expect(all.map((o) => o.source.id), isNot(contains(MarketSeed.tarekId)));
      });

      test('departed legs are gone: exactly at departure counts as passed', () async {
        final trips = offers([
          _offer('of-at', date: _tue, driverId: 'khaled'),
          _offer('of-after', date: _tue, driverId: 'khaled', departure: const Clock.hm(9, 1)),
        ]);
        final w = await once(extra: trips, start: at(_tue, 9, 0));
        final ids = (await going(w)).where((o) => o.date == _tue).map((o) => o.source.id);
        expect(ids, contains('of-after'));
        expect(ids, isNot(contains('of-at')));
      });

      test('a full car is not listed; one seat left is', () async {
        final w = await once(
          extra: {
            ...offers([
              _offer('of-full', date: wed, driverId: 'khaled', seats: 1),
              _offer('of-one', date: wed, driverId: 'khaled', seats: 2),
            ]),
            ...bookings([
              _booking('bk-1', source: const BookingSource.offer('of-full'), date: wed),
              _booking('bk-2', source: const BookingSource.offer('of-one'), date: wed, riderId: 'seed-rider-omar'),
            ]),
          },
        );
        final all = await going(w);
        expect(all.map((o) => o.source.id), isNot(contains('of-full')));
        expect(fromOffer(all, 'of-one').freeSeats, 1);
      });

      test("a driver's own offer is not listed", () async {
        final w = await once(extra: offers([_offer('of-mine', date: wed)]));
        expect((await going(w)).map((o) => o.source.id), isNot(contains('of-mine')));
      });

      test("the rider's own leg is hidden (alreadyRiding): a booked leg-date and a group ride they are on", () async {
        final booked = await once(balance: 100);
        final tarek = fromOffer(await going(booked), MarketSeed.tarekId);
        expect(await booked.repo.book(tarek, now: booked.clock.now), isA<Booked>());
        expect((await going(booked)).where((o) => o.date == wed), isEmpty);

        final member = await _make(role: Role.rider, start: at(_tue, 20, 0));
        expect((await member.daily.ride(wed, Leg.going))!.passengers.map((p) => p.memberId), contains('me'));
        final seats = await going(member);
        expect(seats.where((o) => o.date == wed), isEmpty);
        expect(seats.map((o) => o.source), isNot(contains(const BookingSource.groupSeat('sz-0725'))));
      });

      test('a leg the member cancelled is not one they ride: its seats are listed (no-cover entry)', () async {
        final member = await _make(role: Role.rider, start: at(_tue, 18, 0));
        expect((await going(member)).where((o) => o.date == wed), isEmpty, reason: 'rides it');
        await member.daily.cancel(wed, {Leg.going}, member.clock.now);
        final seats = await going(member);
        expect(seats.where((o) => o.date == wed && o.source.id == MarketSeed.tarekId), hasLength(1));
        final tarek = fromOffer(seats, MarketSeed.tarekId);
        expect(await member.repo.book(tarek, now: member.clock.now), isNot(isA<AlreadyRiding>()));
      });

      test('a full car with a reclaimable booking is listed to a subscriber only (FR-004, US6 AC1)', () async {
        final extra = {
          ...offers([_offer('of-full', date: wed, driverId: 'khaled', seats: 1)]),
          ...bookings([_booking('bk-1', source: const BookingSource.offer('of-full'), date: wed)]),
        };
        final payer = await once(extra: extra);
        expect((await going(payer)).map((o) => o.source.id), isNot(contains('of-full')));

        final subscriber = await once(method: null, company: true, extra: extra);
        expect(fromOffer(await going(subscriber), 'of-full').freeSeats, 1);

        // Past the cut-off the one-off booking is final: nobody can take it.
        final late = await once(method: null, company: true, extra: extra, start: at(_tue, 21, 30));
        expect((await going(late)).map((o) => o.source.id), isNot(contains('of-full')));
      });
    });

    group('book', () {
      OfferedTrip trip({int seats = 3}) => _offer('of-1', date: wed, driverId: 'khaled', seats: seats);

      Future<_World> world({
        PaymentMethod? method = PaymentMethod.wallet,
        int balance = 100,
        bool company = false,
        int seats = 3,
        List<Booking> others = const [],
        WallTime? start,
      }) => once(
        method: method,
        balance: balance,
        company: company,
        start: start,
        extra: {...offers([trip(seats: seats)]), if (others.isNotEmpty) ...bookings(others)},
      );

      Future<SeatOffer> seat(_World w) async => fromOffer(await going(w), 'of-1');

      Booking taken(String riderId) =>
          _booking('bk-9', source: const BookingSource.offer('of-1'), date: wed, riderId: riderId);

      test("wallet 44 is debited once, the seat is kept, and the booking is the rider's", () async {
        final w = await world();
        final offer = await seat(w);
        expect(offer.price.total, 44);

        final result = await w.repo.book(offer, now: w.clock.now);

        final booked = (result as Booked).booking;
        expect((booked.paid, booked.paidBy, booked.status, booked.riderId), (44, PaidBy.wallet, BookingStatus.booked, 'me'));
        expect((booked.date, booked.leg, booked.source), (wed, Leg.going, const BookingSource.offer('of-1')));
        expect(booked.rideId, Booking.offerRideId('of-1'));
        expect(await w.balance(), 56);
        final rows = (await w.activity()).where((e) => e.kind == ActivityKind.seatBooked);
        expect(rows, hasLength(1));
        expect((rows.single.amount, rows.single.fee), (44, 4));
        expect(await w.repo.myBookings(now: w.clock.now), hasLength(1));
      });

      test('the seat count drops by one and the last seat marks the offer full', () async {
        final w = await world(seats: 2, others: [taken('seed-rider-omar')]);
        final offer = await seat(w);
        expect(offer.freeSeats, 1);
        await w.repo.book(offer, now: w.clock.now);

        final stored = jsonDecode(w.prefs.getString(FakeMarketplaceRepository.offersKey)!) as List;
        expect(stored.cast<Map<String, Object?>>().single['status'], OfferStatus.full.name);
        final all = jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List;
        expect(all, hasLength(2));
      });

      test('one booking per rider per leg-date', () async {
        final w = await world();
        final offer = await seat(w);
        expect(await w.repo.book(offer, now: w.clock.now), isA<Booked>());
        expect(await w.repo.book(offer, now: w.clock.now), isA<AlreadyRiding>());
        expect(await w.balance(), 56, reason: 'charged once');
        expect(await w.repo.myBookings(now: w.clock.now), hasLength(1));
      });

      test('seatTaken when the last seat goes between the list and the book — nothing changes (SC-006)', () async {
        final w = await world(seats: 1);
        final offer = await seat(w);
        // Another rider takes it after the list was shown.
        await w.prefs.setString(
          FakeMarketplaceRepository.bookingsKey,
          jsonEncode([taken('seed-rider-omar').toJson()]),
        );

        expect(await w.repo.book(offer, now: w.clock.now), isA<SeatTaken>());

        expect(await w.balance(), 100);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), isEmpty);
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
        final all = jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List;
        expect(all, hasLength(1));
      });

      test('paymentFailed changes nothing', () async {
        final w = await world();
        final offer = await seat(w);
        w.payFails = true;

        expect(await w.repo.book(offer, now: w.clock.now), isA<PaymentFailed>());

        expect(await w.balance(), 100);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), isEmpty);
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
      });

      test('needsMethod without a method or plan; nothing changes', () async {
        final w = await world(method: null, balance: 0);
        expect(await w.repo.book(await seat(w), now: w.clock.now), isA<BookNeedsMethod>());
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
      });

      test('topUp(44) at balance 0, and the booking goes through once the gap is paid', () async {
        final w = await world(balance: 0);
        final offer = await seat(w);
        final blocked = await w.repo.book(offer, now: w.clock.now);
        expect((blocked as BookTopUp).gap, 44);
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);

        await w.wallet.topUp('me', method: 'card', amount: 44);
        expect(await w.repo.book(offer, now: w.clock.now), isA<Booked>());
        expect(await w.balance(), 0);
      });

      test('a company rider at a negative balance is not blocked; no fee', () async {
        final w = await world(method: null, company: true, balance: 0);
        final offer = await seat(w);
        expect((offer.price.fee, offer.price.total), (0, 40));

        final booked = (await w.repo.book(offer, now: w.clock.now) as Booked).booking;

        expect((booked.paidBy, booked.paid, booked.isSubscriber), (PaidBy.plan, 40, true));
        expect(await w.balance(), -40);
      });

      test('cash debits nothing', () async {
        final w = await world(method: PaymentMethod.cash, balance: 0);
        final offer = await seat(w);
        expect(offer.price.payable, offer.price.cash);

        final booked = (await w.repo.book(offer, now: w.clock.now) as Booked).booking;

        expect((booked.paidBy, booked.paid), (PaidBy.cash, 0));
        expect(await w.balance(), 0);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), isEmpty);
      });
    });

    group('cancelBooking', () {
      Future<(_World, Booking)> booked({
        WallTime? start,
        PaymentMethod method = PaymentMethod.wallet,
        int balance = 100,
        int seats = 3,
      }) async {
        final w = await once(
          method: method,
          balance: balance,
          start: start,
          extra: offers([_offer('of-1', date: wed, driverId: 'khaled', seats: seats)]),
        );
        final offer = fromOffer(await going(w), 'of-1');
        return (w, (await w.repo.book(offer, now: w.clock.now) as Booked).booking);
      }

      test('before the cut-off the whole 44 comes back, one refund row, and the seat is free again', () async {
        final (w, b) = await booked(seats: 1);
        w.clock.now = at(_tue, 20, 30);

        final result = await w.repo.cancelBooking(b.id, now: w.clock.now);

        expect((result as BookingCancelled).refund, 44);
        expect(await w.balance(), 100);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatRefund), hasLength(1));
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
        expect(w.repo.charges(), isEmpty);
        // The car was full with that one seat; it is listed again.
        expect(fromOffer(await going(w), 'of-1').freeSeats, 1);
      });

      test('after the cut-off 24 comes back; owed 20 is a lateCancel charge to the driver, the fee goes back', () async {
        final (w, b) = await booked(start: at(_tue, 21, 30));
        w.clock.now = at(_tue, 21, 45);

        final result = await w.repo.cancelBooking(b.id, now: w.clock.now);

        expect((result as BookingCancelled).refund, 24);
        expect(await w.balance(), 100 - 44 + 24);
        final charge = w.repo.charges().single;
        expect((charge.amount, charge.reason, charge.personId, charge.owedTo), (20, ChargeReason.lateCancel, 'me', 'khaled'));
        expect(charge.rideId, b.rideId);
      });

      test('a cash booking: nothing to refund; owed half after the cut-off, nothing before', () async {
        final (early, e) = await booked(method: PaymentMethod.cash, balance: 0);
        expect(((await early.repo.cancelBooking(e.id, now: early.clock.now)) as BookingCancelled).refund, 0);
        expect(early.repo.charges(), isEmpty);

        final (late, l) = await booked(method: PaymentMethod.cash, balance: 0, start: at(_tue, 21, 30));
        expect(((await late.repo.cancelBooking(l.id, now: late.clock.now)) as BookingCancelled).refund, 0);
        expect(late.repo.charges().single.amount, 20);
        expect(await late.balance(), 0);
      });

      test('twice, unknown, or after pickup is NotCancellable', () async {
        final (w, b) = await booked();
        expect(await w.repo.cancelBooking(b.id, now: w.clock.now), isA<BookingCancelled>());
        expect(await w.repo.cancelBooking(b.id, now: w.clock.now), isA<NotCancellable>());
        expect(await w.repo.cancelBooking('bk-nope', now: w.clock.now), isA<NotCancellable>());
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatRefund), hasLength(1));

        final (v, c) = await booked();
        v.clock.now = at(wed, 9, 0);
        expect(await v.repo.cancelBooking(c.id, now: v.clock.now), isA<NotCancellable>());
      });
    });

    group('myBookings', () {
      test('booked and not ended, oldest first — cancelled and finished ones are left out', () async {
        final w = await once(
          extra: {
            ...offers([
              _offer('of-old', date: _tue.addDays(-1), driverId: 'khaled'),
              _offer('of-wed', date: wed, driverId: 'khaled'),
              _offer('of-thu', date: thu, driverId: 'khaled'),
            ]),
            ...bookings([
              _booking('bk-3', source: const BookingSource.offer('of-thu'), date: thu, riderId: 'me'),
              _booking('bk-1', source: const BookingSource.offer('of-wed'), date: wed, riderId: 'me'),
              _booking('bk-2', source: const BookingSource.offer('of-wed'), date: wed, riderId: 'me', status: BookingStatus.cancelled),
              _booking('bk-0', source: const BookingSource.offer('of-old'), date: _tue.addDays(-1), riderId: 'me'),
              _booking('bk-8', source: const BookingSource.offer('of-wed'), date: wed, riderId: 'seed-rider-omar'),
            ]),
          },
        );
        final mine = await w.repo.myBookings(now: w.clock.now);
        expect(mine.map((b) => b.id), ['bk-1', 'bk-3']);
      });
    });
  });

  group('Offer a trip (T063, US2)', () {
    final wed = _tue.addDays(1);

    Map<String, Object> offers(List<OfferedTrip> trips) =>
        _stored(FakeMarketplaceRepository.offersKey, [for (final t in trips) t.toJson()]);
    Map<String, Object> bookings(List<Booking> items) =>
        _stored(FakeMarketplaceRepository.bookingsKey, [for (final b in items) b.toJson()]);

    /// A verified driver with no group.
    Future<_World> driver({WallTime? start, Map<String, Object> extra = const {}, bool member = false}) =>
        _make(role: Role.driver, member: member, start: start, extra: extra);

    OfferDraft draft({
      Leg leg = Leg.going,
      Clock departure = const Clock.hm(7, 30),
      int seats = 3,
      int contribution = 40,
      Repeat repeat = Repeat.once,
    }) => OfferDraft(
      leg: leg,
      from: leg == Leg.going ? Area.sheikhZayed : Area.smartVillage,
      to: leg == Leg.going ? Area.smartVillage : Area.sheikhZayed,
      departure: departure,
      seats: seats,
      contribution: contribution,
      repeat: repeat,
    );

    group('publish', () {
      test('a driver with unverified documents is told which, and publishes after the demo verify', () async {
        final w = await driver();
        await w.trust.startDriverVerification();
        final refused = await w.repo.publish(draft(), now: w.clock.now);
        expect(refused, isA<NotVerified>());
        expect((refused as NotVerified).missing, [VerificationKind.license, VerificationKind.vehicle]);

        await w.trust.demoVerifyDriver();
        expect(await w.repo.publish(draft(), now: w.clock.now), isA<Published>());
      });

      test('publishes on the next workday at the chosen time with the corridor basis and a public pickup', () async {
        final w = await driver(); // Tue 20:00 — 7:30 is tomorrow
        final result = await w.repo.publish(draft(), now: w.clock.now) as Published;
        final t = result.trip;
        expect((t.id, t.driverId, t.date, t.departure, t.seats, t.riderSeats, t.tripCost, t.contribution), (
          'of-1',
          'me',
          wed,
          const Clock.hm(7, 30),
          3,
          3,
          160,
          40,
        ));
        expect((t.status, t.repeat, t.origin), (OfferStatus.open, Repeat.once, OfferOrigin.published));
        expect(t.pickup.name, StopName.mainGate);
        expect((await w.repo.offer('of-1', now: w.clock.now))?.id, 'of-1');
        expect((await w.repo.driverDay(wed)).trips.map((x) => x.id), ['of-1']);
      });

      test('ids count up past the seeded and stored ones', () async {
        final w = await driver(extra: offers([_offer('of-7', date: wed, driverId: 'khaled')]));
        final t = (await w.repo.publish(draft(), now: w.clock.now) as Published).trip;
        expect(t.id, 'of-8');
      });

      test('a price outside the range is a bug, not a result — 32 and 48 are the ends at 160 / 3 seats', () async {
        final w = await driver();
        expect(() => w.repo.publish(draft(contribution: 30), now: w.clock.now), throwsArgumentError);
        expect(() => w.repo.publish(draft(contribution: 50), now: w.clock.now), throwsArgumentError);
        expect(await w.repo.publish(draft(contribution: 32), now: w.clock.now), isA<Published>());
        final w2 = await driver();
        expect(await w2.repo.publish(draft(contribution: 48), now: w2.clock.now), isA<Published>());
      });

      test("the daily limit: join, doesn't fit, create, then limit reached — every refusal is OverLimit", () async {
        final w = await driver();
        expect(await w.repo.publish(draft(), now: w.clock.now), isA<Published>());

        // 15 min from the first, same route and leg, seats left → joins it.
        var r = await w.repo.publish(draft(departure: const Clock.hm(7, 45)), now: w.clock.now) as OverLimit;
        expect((r.fit.kind, r.fit.tripId), (TripFitKind.join, 'of-1'));

        // Same leg, far from the first → doesn't fit.
        r = await w.repo.publish(draft(departure: const Clock.hm(11, 0)), now: w.clock.now) as OverLimit;
        expect(r.fit.kind, TripFitKind.doesntFit);

        // The other leg is the second trip.
        expect(
          await w.repo.publish(draft(leg: Leg.ret, departure: const Clock.hm(17, 0)), now: w.clock.now),
          isA<Published>(),
        );

        // A third trip is over the day's two.
        r = await w.repo.publish(draft(departure: const Clock.hm(12, 0)), now: w.clock.now) as OverLimit;
        expect(r.fit.kind, TripFitKind.limitReached);
      });

      test('a driver who leads a daily group cannot publish Every workday on a day they do not drive', () async {
        final w = await driver(member: true); // sz-0725: their turn is Thursday, not Wednesday
        final r = await w.repo.publish(draft(repeat: Repeat.daily), now: w.clock.now) as OverLimit;
        expect(r.fit.kind, TripFitKind.oneGroupOnly);
        expect(await w.repo.publish(draft(), now: w.clock.now), isA<Published>(), reason: 'Just once is fine');
      });
    });

    group('live', () {
      test('anonymous riders before departure, first names from departure, oldest first', () async {
        final trip = _offer('of-9', date: wed, departure: const Clock.hm(9, 0));
        final w = await driver(
          extra: {
            ...offers([trip]),
            ...bookings([
              _booking(
                'bk-2',
                source: const BookingSource.offer('of-9'),
                date: wed,
                riderId: 'seed-rider-omar',
                bookedAt: at(_tue, 11, 0),
              ),
              _booking(
                'bk-1',
                source: const BookingSource.offer('of-9'),
                date: wed,
                riderId: 'seed-rider-nadia',
                bookedAt: at(_tue, 10, 0),
              ),
              _booking('bk-3', source: const BookingSource.offer('of-9'), date: wed, status: BookingStatus.cancelled),
            ]),
          },
        );
        var live = await w.repo.live('of-9', now: w.clock.now);
        expect((live.taken, live.isFull, live.trip.seats), (2, false, 3));
        expect(live.riders.map((r) => r.firstName), [null, null]);

        w.clock.now = at(wed, 9, 0);
        live = await w.repo.live('of-9', now: w.clock.now);
        expect(live.riders.map((r) => r.firstName), ['Nadia', 'Nadia']);
      });

      test('status follows the clock: open → departed → done; a full car is full', () async {
        final trip = _offer('of-9', date: wed, departure: const Clock.hm(9, 0), seats: 2);
        final w = await driver(
          extra: {
            ...offers([trip]),
            ...bookings([
              _booking('bk-1', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-nadia'),
              _booking('bk-2', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-omar'),
            ]),
          },
        );
        expect((await w.repo.live('of-9', now: w.clock.now)).isFull, isTrue);
        expect((await w.repo.offer('of-9', now: at(wed, 8, 59)))?.status, OfferStatus.open);
        expect((await w.repo.offer('of-9', now: at(wed, 9, 0)))?.status, OfferStatus.departed);
        expect((await w.repo.offer('of-9', now: at(wed, 9, 40)))?.status, OfferStatus.done);
        expect(await w.repo.offer('nope', now: w.clock.now), isNull);
      });
    });

    group('demoRiderBooks', () {
      test('nothing to book when the driver has no open offer', () async {
        final w = await driver();
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoNothing>());
      });

      test('books the latest open offer from the rider pool, one rider at a time, until full', () async {
        final w = await driver();
        await w.repo.publish(draft(seats: 2, contribution: 44), now: w.clock.now);
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoDone>());
        var live = await w.repo.live('of-1', now: w.clock.now);
        expect(live.taken, 1);
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoDone>());
        live = await w.repo.live('of-1', now: w.clock.now);
        expect((live.taken, live.isFull), (2, true));
        expect((await w.repo.offer('of-1', now: w.clock.now))?.status, OfferStatus.full);
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoNothing>());
      });

      test("a daily offer's first booking becomes a one-leg mk- group the driver joins, booking re-keyed (R10)", () async {
        final w = await driver();
        await w.repo.publish(draft(repeat: Repeat.daily), now: w.clock.now);
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoDone>());

        final g = GroupCatalog(w.prefs).byId('mk-of-1')!;
        expect((g.origin, g.destination, g.price, g.tripCost, g.riderSeats), (
          Area.sheikhZayed,
          Area.smartVillage,
          40,
          160,
          3,
        ));
        expect(g.legs, {Leg.going});
        expect(g.members.map((m) => m.id), ['seed-rider-nadia']);
        expect(g.days, MarketDay.workdays);
        expect(g.rotationStart, _tue.addDays(-2), reason: 'the Sunday of the offer week');

        expect((await w.repo.offer('of-1', now: w.clock.now))?.status, OfferStatus.grouped);
        expect((await w.repo.offer('of-1', now: w.clock.now))?.groupId, 'mk-of-1');
        expect(await FakeCommuteRepository(w.prefs, catalog: GroupCatalog(w.prefs)).joinedGroupId(), 'mk-of-1');

        final stored = jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List;
        expect(stored.map((b) => (b as Map)['rideId']), [Ride.idFor('mk-of-1', wed, Leg.going)]);
        // Counted once on the driver's day: as the group's leg, not also as an offer.
        expect((await w.repo.driverDay(wed)).trips, hasLength(1));
        // The driver is in the group, so the group is theirs.
        expect((await w.daily.myGroup())?.id, 'mk-of-1');
      });

      test('a daily return offer becomes a group the right way round: home → work, picked up at work (T104 F10)', () async {
        final w = await driver();
        await w.repo.publish(draft(leg: Leg.ret, departure: const Clock.hm(17, 0), repeat: Repeat.daily), now: w.clock.now);
        expect(await w.repo.demoRiderBooks(now: w.clock.now), isA<DemoDone>());

        final g = GroupCatalog(w.prefs).byId('mk-of-1')!;
        expect((g.origin, g.destination), (Area.sheikhZayed, Area.smartVillage), reason: 'a group runs home → work');
        expect(g.legs, {Leg.ret});
        expect((g.workStop.name, g.workStop.time), (StopName.smartVillageGate2, const Clock.hm(17, 0)),
            reason: 'the return leg starts at the offer pickup');
        final sv = MarketSeed.pointIn(Area.smartVillage);
        expect((g.workStop.point.lat, g.workStop.point.lng), (sv.lat, sv.lng));
        expect(g.goingStops.single.name, StopName.mainGate, reason: 'the return leg ends at home');
        expect(g.endFor(Leg.ret), const Clock.hm(17, 40));
      });

      test('a once offer stays an offer', () async {
        final w = await driver();
        await w.repo.publish(draft(), now: w.clock.now);
        await w.repo.demoRiderBooks(now: w.clock.now);
        expect(GroupCatalog(w.prefs).byId('mk-of-1'), isNull);
        final stored = jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List;
        expect(stored.map((b) => (b as Map)['rideId']), [Booking.offerRideId('of-1')]);
      });
    });

    group('cancelOffer', () {
      Future<_World> withRiders({WallTime? start}) => driver(
        start: start,
        extra: {
          ...offers([_offer('of-9', date: wed, departure: const Clock.hm(9, 0))]),
          ...bookings([
            _booking('bk-1', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-nadia'),
            _booking('bk-2', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-omar'),
          ]),
        },
      );

      Future<int> notices(_World w, NoticeKind kind) async =>
          (await w.daily.notices().first).where((n) => n.kind == kind).length;

      test('every booking is refunded, each rider is told, and the trip still counts on the day (SC-005)', () async {
        final w = await withRiders();
        await w.repo.cancelOffer('of-9', now: w.clock.now);

        final stored = (jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List).cast<Map<String, Object?>>();
        expect(stored.map((b) => b['status']), everyElement(BookingStatus.refunded.name));
        expect((await w.repo.offer('of-9', now: w.clock.now))?.status, OfferStatus.cancelled);
        expect(await notices(w, NoticeKind.tripCancelledByDriver), 2);
        expect((await w.repo.driverDay(wed)).trips.map((t) => (t.id, t.taken)), [('of-9', 3)]);
      });

      test('a rider with money paid gets all of it back, fee included', () async {
        final w = await driver(
          extra: {
            ...offers([_offer('of-9', date: wed, driverId: 'khaled')]),
            ...bookings([_booking('bk-1', source: const BookingSource.offer('of-9'), date: wed, riderId: 'me')]),
          },
        );
        await w.wallet.topUp('me', method: 'card', amount: 200);
        await w.repo.cancelOffer('of-9', now: w.clock.now);
        expect(await w.balance(), 244);
      });

      test('a late cancel with riders counts once on reliability; an early or empty one does not', () async {
        final late = await withRiders(start: at(_tue, 21, 30));
        await late.repo.cancelOffer('of-9', now: late.clock.now);
        await late.repo.cancelOffer('of-9', now: late.clock.now); // a second call changes nothing
        var events = await late.daily.events(_tue, wed);
        expect(events.map((e) => (e.kind, e.rideId)), [(ReliabilityEventKind.lateCantDrive, 'offer:of-9')]);

        final early = await withRiders(start: at(_tue, 20, 0));
        await early.repo.cancelOffer('of-9', now: early.clock.now);
        expect(await early.daily.events(_tue, wed), isEmpty);

        final empty = await driver(start: at(_tue, 21, 30), extra: offers([_offer('of-9', date: wed)]));
        await empty.repo.cancelOffer('of-9', now: empty.clock.now);
        events = await empty.daily.events(_tue, wed);
        expect(events, isEmpty);
        expect((await empty.repo.driverDay(wed)).trips, isEmpty, reason: 'no riders: the day is free again');
      });
    });
  });

  group('Post your trip (T074, US3)', () {
    final wed = _tue.addDays(1);

    Future<_World> rider({
      PaymentMethod? method = PaymentMethod.wallet,
      int balance = 0,
      bool member = false,
      WallTime? start,
      Map<String, Object> extra = const {},
    }) async {
      final w = await _make(role: Role.rider, member: member, method: method, start: start, extra: extra);
      if (balance > 0) await w.wallet.topUp('me', method: 'card', amount: balance);
      return w;
    }

    TripDraft draft({Repeat repeat = Repeat.once, Clock departure = const Clock.hm(7, 30)}) => TripDraft(
      leg: Leg.going,
      from: Area.sheikhZayed,
      to: Area.smartVillage,
      departure: departure,
      repeat: repeat,
    );

    Future<List<Object?>> notices(_World w, NoticeKind kind) async =>
        [for (final n in await w.daily.notices().first) if (n.kind == kind) n.params];

    group('post', () {
      test('no method and no plan → needsMethod', () async {
        final w = await rider(method: null);
        expect(await w.repo.post(draft(), now: w.clock.now), isA<PostNeedsMethod>());
      });

      test('the wallet must cover the route price: topUp(gap) with the gap in EGP', () async {
        final w = await rider(balance: 10);
        final r = await w.repo.post(draft(), now: w.clock.now);
        expect((r as PostTopUp).gap, 34, reason: '44 − 10');
      });

      test('a rider already in a daily group cannot post Every workday, but can post once', () async {
        final w = await rider(member: true);
        expect(await w.repo.post(draft(repeat: Repeat.daily), now: w.clock.now), isA<DailyNotAllowed>());
        expect(await w.repo.post(draft(), now: w.clock.now), isA<Posted>());
      });

      test('posted: a fixed price at the 3-seat basis, the next workday, anonymous', () async {
        final w = await rider(balance: 100);
        final posted = await w.repo.post(draft(), now: w.clock.now) as Posted;
        final r = posted.request;
        expect((r.id, r.riderId, r.date, r.status, r.repeat), ('rq-1', 'me', wed, RequestStatus.posted, Repeat.once));
        expect((r.price.contribution, r.price.fee, r.price.total), (40, 4, 44));
        expect(r.pickup.name, StopName.mainGate);
        expect((await w.repo.request('rq-1', now: w.clock.now))?.id, 'rq-1');
        expect(await w.balance(), 100, reason: 'nothing is charged for posting');
      });

      test('Sent to N: every fake driver on the route whose privacy accepts the rider', () async {
        final w = await rider(balance: 100);
        expect(await w.repo.driversOnRoute(draft()), 4);
        final women = await _make(
          role: Role.rider,
          member: false,
          method: PaymentMethod.wallet,
          gender: Gender.female,
          extra: {FakeTrustRepository.privacyKey: PrivacyPreference.womenOnly.name},
        );
        expect(await women.repo.driversOnRoute(draft()), 2, reason: 'Heba and Mariam');
      });

      test('cancelling is free and the request stays as cancelled', () async {
        final w = await rider(balance: 100);
        await w.repo.post(draft(), now: w.clock.now);
        await w.repo.cancelRequest('rq-1');
        expect((await w.repo.request('rq-1', now: w.clock.now))?.status, RequestStatus.cancelled);
        expect(await w.balance(), 100);
      });
    });

    group('expiry (SC-005)', () {
      test('at departure the request expires on read: no charge, no ledger row, one notice', () async {
        final w = await rider(balance: 100);
        await w.repo.post(draft(), now: w.clock.now);
        final before = (await w.activity()).length;
        w.clock.now = at(wed, 7, 30);
        expect((await w.repo.request('rq-1', now: w.clock.now))?.status, RequestStatus.expired);
        expect((await w.repo.request('rq-1', now: w.clock.now))?.status, RequestStatus.expired);
        expect(await w.balance(), 100);
        expect((await w.activity()).length, before);
        expect(await notices(w, NoticeKind.requestExpired), hasLength(1), reason: 'told once');
      });

      test('a day before departure it is still posted', () async {
        final w = await rider(balance: 100);
        await w.repo.post(draft(), now: w.clock.now);
        w.clock.now = at(wed, 7, 29);
        expect((await w.repo.request('rq-1', now: w.clock.now))?.status, RequestStatus.posted);
      });
    });

    group('demoDriverAccepts', () {
      test('nothing to accept without a posted request', () async {
        final w = await rider(balance: 100);
        expect(await w.repo.demoDriverAccepts(now: w.clock.now), isA<DemoNothing>());
      });

      test('a once request: the rider pays at accept (−44), is seated, and is told', () async {
        final w = await rider(balance: 100);
        await w.repo.post(draft(), now: w.clock.now);
        expect(await w.repo.demoDriverAccepts(now: w.clock.now), isA<DemoDone>());

        expect(await w.balance(), 56);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), hasLength(1));
        final r = (await w.repo.request('rq-1', now: w.clock.now))!;
        expect((r.status, r.acceptedBy), (RequestStatus.accepted, 'tarek'));
        final trip = (await w.repo.offer(r.tripId!, now: w.clock.now))!;
        expect((trip.origin, trip.seats, trip.riderSeats, trip.contribution), (OfferOrigin.fromRequest, 3, 3, 40));
        final mine = await w.repo.myBookings(now: w.clock.now);
        expect(mine.map((b) => (b.source, b.paid)), [(BookingSource.offer(trip.id), 44)]);
        expect(await notices(w, NoticeKind.requestAccepted), hasLength(1));
      });

      test('a daily request becomes an mk- group the rider joins — nothing is charged at accept (FR-013)', () async {
        // Payment set up today, so 003's demo history before it is not billed.
        final w = await rider(balance: 100, extra: {FakeWalletRepository.sinceKey(DailySeed.meId): _tue.toIso()});
        await w.repo.post(draft(repeat: Repeat.daily), now: w.clock.now);
        await w.repo.demoDriverAccepts(now: w.clock.now);

        final g = GroupCatalog(w.prefs).byId('mk-rq-1')!;
        expect(g.legs, {Leg.going});
        expect((g.price, g.tripCost, g.riderSeats), (40, 160, 3));
        expect(g.drivers.map((d) => d.id), ['tarek']);
        expect(await FakeCommuteRepository(w.prefs, catalog: GroupCatalog(w.prefs)).joinedGroupId(), 'mk-rq-1');
        expect(await w.balance(), 100);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), isEmpty);
        expect((await w.repo.request('rq-1', now: w.clock.now))?.tripId, Ride.idFor('mk-rq-1', wed, Leg.going));
      });

      test('a rider who can no longer pay at accept has the request withdrawn and nothing charged', () async {
        final w = await rider(balance: 44);
        await w.repo.post(draft(), now: w.clock.now);
        await w.wallet.debitSeat('me', bookingId: 'bk-x', rideId: 'offer:x', total: 44, fee: 4, date: wed);
        expect(await w.balance(), 0);
        expect(await w.repo.demoDriverAccepts(now: w.clock.now), isA<DemoDone>());

        expect((await w.repo.request('rq-1', now: w.clock.now))?.status, RequestStatus.withdrawn);
        expect(await w.balance(), 0);
        expect((await w.activity()).where((e) => e.kind == ActivityKind.seatBooked), hasLength(1), reason: 'only the setup debit');
        expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
      });
    });
  });

  group('Find riders (T083, US4)', () {
    final wed = _tue.addDays(1);

    Future<_World> driver() => _make(role: Role.driver, member: false);

    Future<List<RequestCard>> morning(_World w, {Area? leavingFrom = Area.sheikhZayed}) =>
        w.repo.requestsForMe(leavingFrom: leavingFrom, part: PartOfDay.morning, now: w.clock.now);

    test('the corridor: 12 in the morning and 4 in the evening, earliest first, anonymous', () async {
      final w = await driver();
      final cards = await morning(w);
      expect(cards, hasLength(12));
      expect(cards.map((c) => c.departure.minutes), orderedEquals([...cards.map((c) => c.departure.minutes)]..sort()));
      expect(cards.first.requestId, 'rq-seed-m01');
      expect((cards.first.date, cards.first.price.total), (wed, 44));
      final evening = await w.repo.requestsForMe(leavingFrom: Area.sheikhZayed, part: PartOfDay.evening, now: w.clock.now);
      expect(evening, hasLength(4));
      expect(evening.map((c) => c.leg).toSet(), {Leg.ret});
    });

    test('Leaving from: October sees fewer; All sees every request near any area', () async {
      final w = await driver();
      final october = await morning(w, leavingFrom: Area.october);
      expect(october.length, inInclusiveRange(1, 11));
      expect(october.every((c) => c.detourMinutes < 10), isTrue);
      expect(await morning(w, leavingFrom: null), hasLength(12));
    });

    test("a driver's own women-only privacy shows women riders only", () async {
      final w = await _make(
        role: Role.driver,
        member: false,
        gender: Gender.female,
        extra: {FakeTrustRepository.privacyKey: PrivacyPreference.womenOnly.name},
      );
      final cards = await morning(w);
      expect(cards, isNotEmpty);
      expect(cards.map((c) => c.rider.isWoman).toSet(), {true});
    });

    test('a request that expired or was accepted leaves the list', () async {
      final w = await driver();
      await w.repo.accept('rq-seed-m02', now: w.clock.now);
      expect((await morning(w)).map((c) => c.requestId), isNot(contains('rq-seed-m02')));
      // The corridor's requests are always ahead of the clock: what has left is re-dated to the next day.
      w.clock.now = at(wed, 7, 20);
      final left = (await morning(w)).where((c) => c.departure.minutes <= 7 * 60 + 20);
      expect(left, isNotEmpty);
      expect(left.map((c) => c.date).toSet(), {wed.addDays(1)});
    });

    test('accept creates a trip from the request: its price, 3 seats, origin fromRequest → created(1)', () async {
      final w = await driver();
      final r = await w.repo.accept('rq-seed-m02', now: w.clock.now);
      expect((r as AcceptCreated).tripsLeft, 1);
      final day = await w.repo.driverDay(wed);
      expect(day.trips, hasLength(1));
      final trip = (await w.repo.offer(day.trips.single.id, now: w.clock.now))!;
      expect((trip.origin, trip.seats, trip.riderSeats, trip.contribution, trip.repeat), (
        OfferOrigin.fromRequest,
        3,
        3,
        40,
        Repeat.once,
      ));
      expect((await w.repo.live(trip.id, now: w.clock.now)).taken, 1);
    });

    test('the quickstart §5 sequence: trips left 2 → 1 → 1 → 0, then Daily limit reached', () async {
      final w = await driver();
      expect((await w.repo.driverDay(wed)).tripsLeft, 2);
      expect((await w.repo.accept('rq-seed-m02', now: w.clock.now) as AcceptCreated).tripsLeft, 1); // 7:05
      final joined = await w.repo.accept('rq-seed-m03', now: w.clock.now); // 7:10, within 30
      expect((joined as AcceptJoined).time, const Clock.hm(7, 5));
      expect((await w.repo.driverDay(wed)).tripsLeft, 1, reason: 'a join uses no extra trip');
      expect((await w.repo.accept('rq-seed-e01', now: w.clock.now) as AcceptCreated).tripsLeft, 0); // the way back
      final refused = await w.repo.accept('rq-seed-m09', now: w.clock.now); // 7:40: 35 min from 7:05
      expect((refused as AcceptRefused).fit.kind, TripFitKind.limitReached);
    });

    test('a car that is full says so: the 4th request near the same time is refused as full', () async {
      final w = await driver();
      await w.repo.accept('rq-seed-m02', now: w.clock.now);
      await w.repo.accept('rq-seed-m03', now: w.clock.now);
      await w.repo.accept('rq-seed-m05', now: w.clock.now); // 7:20
      final cards = await morning(w);
      expect(cards.firstWhere((c) => c.requestId == 'rq-seed-m06').fit.kind, TripFitKind.full);
      final refused = await w.repo.accept('rq-seed-m06', now: w.clock.now);
      expect((refused as AcceptRefused).fit.kind, TripFitKind.full);
    });

    test('a request already taken is gone: the second accept changes nothing', () async {
      final w = await driver();
      await w.repo.accept('rq-seed-m02', now: w.clock.now);
      expect(await w.repo.accept('rq-seed-m02', now: w.clock.now), isA<RiderCantPay>());
      expect((await w.repo.driverDay(wed)).trips.single.taken, 1);
    });

    test('a daily request accepted into a new trip makes an mk- group the driver joins', () async {
      final w = await driver();
      final r = await w.repo.accept('rq-seed-m01', now: w.clock.now); // daily, 7:00
      expect(r, isA<AcceptCreated>());
      final g = GroupCatalog(w.prefs).byId('mk-rq-seed-m01')!;
      expect(g.legs, {Leg.going});
      expect(g.members.map((m) => m.id), ['seed-m01']);
      expect(await FakeCommuteRepository(w.prefs, catalog: GroupCatalog(w.prefs)).joinedGroupId(), 'mk-rq-seed-m01');
    });
  });

  group('Subscriber priority and full refund (T093, US6)', () {
    final wed = _tue.addDays(1);
    final thu = _tue.addDays(2);

    Map<String, Object> offers(List<OfferedTrip> trips) =>
        _stored(FakeMarketplaceRepository.offersKey, [for (final t in trips) t.toJson()]);
    Map<String, Object> bookings(List<Booking> items) =>
        _stored(FakeMarketplaceRepository.bookingsKey, [for (final b in items) b.toJson()]);

    Future<_World> rider({
      PaymentMethod? method = PaymentMethod.wallet,
      int balance = 0,
      bool company = false,
      WallTime? start,
      Map<String, Object> extra = const {},
    }) async {
      final w = await _make(
        role: Role.rider,
        member: false,
        method: method,
        start: start ?? at(_tue, 12, 0),
        extra: {
          if (company)
            FakeWalletRepository.planKey: jsonEncode(
              const Plan(personId: DailySeed.meId, type: PlanType.company, status: PlanStatus.active, price: 0).toJson(),
            ),
          ...extra,
        },
      );
      if (balance > 0) await w.wallet.topUp('me', method: 'card', amount: balance);
      return w;
    }

    Future<Booked> bookOf(_World w, String tripId) async {
      final seats = await w.repo.seatOffers(Leg.going, now: w.clock.now);
      final seat = seats.firstWhere((s) => s.source == BookingSource.offer(tripId));
      return await w.repo.book(seat, now: w.clock.now) as Booked;
    }

    final khaled = {...offers([_offer('of-9', date: wed, departure: const Clock.hm(9, 0), driverId: 'khaled')])};

    test('before 9 PM the evening before: reclaimed, one refund of 44, the balance is back to what it was (SC-005)',
        () async {
      final w = await rider(balance: 200, extra: khaled);
      final booked = await bookOf(w, 'of-9');
      expect(await w.balance(), 156);

      final r = await w.repo.reclaim(booked.booking.id, now: w.clock.now);
      expect((r as Reclaimed).refund, 44);
      expect(await w.balance(), 200);
      final refunds = (await w.activity()).where((e) => e.kind == ActivityKind.seatRefund);
      expect(refunds.map((e) => e.amount), [44]);
      final told = [for (final n in await w.daily.notices().first) if (n.kind == NoticeKind.seatReclaimed) n.params];
      expect(told, [
        {'day': wed.toIso(), 'amount': '44'},
      ]);
      expect(await w.repo.myBookings(now: w.clock.now), isEmpty);
    });

    test('at 9 PM or later it is final: tooLate, nothing moves', () async {
      final w = await rider(balance: 200, extra: khaled);
      final booked = await bookOf(w, 'of-9');
      w.clock.now = at(_tue, 21, 0);
      expect(await w.repo.reclaim(booked.booking.id, now: w.clock.now), isA<ReclaimTooLate>());
      expect(await w.balance(), 156);
    });

    test('a seat booked after the cut-off can never be reclaimed', () async {
      final w = await rider(balance: 200, start: at(_tue, 21, 30), extra: khaled);
      final booked = await bookOf(w, 'of-9');
      expect(await w.repo.reclaim(booked.booking.id, now: at(_tue, 21, 31)), isA<NotReclaimable>());
    });

    test("a subscriber's own seat is never reclaimed", () async {
      final w = await rider(method: null, company: true, extra: khaled);
      final booked = await bookOf(w, 'of-9');
      expect(booked.booking.isSubscriber, isTrue);
      expect(await w.repo.reclaim(booked.booking.id, now: w.clock.now), isA<NotReclaimable>());
    });

    test('a cash booking moves no money and does not count toward the 10 cash trips', () async {
      final w = await rider(method: PaymentMethod.cash, extra: khaled);
      final booked = await bookOf(w, 'of-9');
      expect(booked.booking.paid, 0);
      final r = await w.repo.reclaim(booked.booking.id, now: w.clock.now);
      expect((r as Reclaimed).refund, 0);
      expect(await w.balance(), 0);
      expect((await w.activity()).where((e) => e.kind == ActivityKind.seatRefund), isEmpty);
      w.clock.now = at(wed, 10, 0);
      expect(await w.repo.doneOneOffs(), isEmpty);
    });

    test('a subscriber books a full car by taking the newest reclaimable seat (US6 AC1)', () async {
      final full = _offer('of-9', date: wed, departure: const Clock.hm(9, 0), driverId: 'khaled', seats: 1);
      final w = await rider(
        method: null,
        company: true,
        extra: {
          ...offers([full]),
          ...bookings([
            _booking('bk-1', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-nadia', bookedAt: at(_tue, 10, 0)),
          ]),
        },
      );
      final seats = await w.repo.seatOffers(Leg.going, now: w.clock.now);
      expect(seats.where((s) => s.source == const BookingSource.offer('of-9')), hasLength(1), reason: 'a subscriber still sees it');

      final booked = await bookOf(w, 'of-9');
      final stored = (jsonDecode(w.prefs.getString(FakeMarketplaceRepository.bookingsKey)!) as List).cast<Map<String, Object?>>();
      expect({for (final b in stored) b['id']: b['status']}, {
        'bk-1': BookingStatus.reclaimed.name,
        booked.booking.id: BookingStatus.booked.name,
      });
    });

    test('a non-subscriber never sees that full car', () async {
      final full = _offer('of-9', date: wed, departure: const Clock.hm(9, 0), driverId: 'khaled', seats: 1);
      final w = await rider(
        balance: 200,
        extra: {
          ...offers([full]),
          ...bookings([
            _booking('bk-1', source: const BookingSource.offer('of-9'), date: wed, riderId: 'seed-rider-nadia', bookedAt: at(_tue, 10, 0)),
          ]),
        },
      );
      final seats = await w.repo.seatOffers(Leg.going, now: w.clock.now);
      expect(seats.where((s) => s.source == const BookingSource.offer('of-9')), isEmpty);
    });

    test('demoSubscriberTakes takes the rider\'s latest booking, then says too late after 9 PM', () async {
      final w = await rider(
        balance: 400,
        extra: offers([
          _offer('of-9', date: wed, departure: const Clock.hm(9, 0), driverId: 'khaled'),
          _offer('of-8', date: thu, departure: const Clock.hm(9, 0), driverId: 'khaled'),
        ]),
      );
      expect(await w.repo.demoSubscriberTakes(now: w.clock.now), isA<DemoNothing>());
      await bookOf(w, 'of-9');
      w.clock.now = at(_tue, 13, 0);
      await bookOf(w, 'of-8');
      expect(await w.repo.demoSubscriberTakes(now: w.clock.now), isA<DemoDone>());
      expect((await w.repo.myBookings(now: w.clock.now)).map((b) => b.date), [wed], reason: 'the newest one went');

      w.clock.now = at(_tue, 21, 5);
      expect(await w.repo.demoSubscriberTakes(now: w.clock.now), isA<DemoTooLate>());
    });
  });
}
