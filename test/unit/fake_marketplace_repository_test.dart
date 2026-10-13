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
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/data/fake_trust_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/marketplace/data/fake_marketplace_repository.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/domain/anonymous_rider.dart';
import 'package:goora/features/marketplace/domain/booking.dart';
import 'package:goora/features/marketplace/domain/market_day.dart';
import 'package:goora/features/marketplace/domain/offered_trip.dart';
import 'package:goora/features/marketplace/domain/trip_request.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 005 T041 (seed) and T043 (driver day, R5) on the real fakes — no mocks.

/// Tue 6 Oct 2026 is a ride day of sz-0725 (rotation start Sun 4 Oct); Thu 8
/// Oct is the person's turn to drive when they join as a driver.
final _tue = rideTuesday;
final _thu = _tue.addDays(2);

final class _World {
  _World(this.repo, this.daily, this.prefs, this.clock);

  final FakeMarketplaceRepository repo;
  final FakeDailyCommuteRepository daily;
  final SharedPreferences prefs;
  final TestClock clock;
}

Future<_World> _make({
  Role role = Role.driver,
  bool member = true,
  Map<String, Object> extra = const {},
  WallTime? start,
}) async {
  SharedPreferences.setMockInitialValues({...memberPrefs(role: role, member: member), ...extra});
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(start ?? at(_tue, 20, 0));
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role);
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
    provider: FakePaymentProvider(),
  );
  final repo = FakeMarketplaceRepository(
    prefs,
    catalog: catalog,
    daily: daily,
    notices: daily,
    ledger: () => wallet,
    wallet: () => wallet,
    trust: FakeTrustRepository(prefs, person: () => person, now: clock.call),
    now: clock.call,
  );
  return _World(repo, daily, prefs, clock);
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
}) => OfferedTrip(
  id: id,
  driverId: driverId,
  leg: leg,
  from: leg == Leg.going ? Area.sheikhZayed : Area.smartVillage,
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
  bookedAt: at(date.addDays(-2), 12, 0),
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
}
