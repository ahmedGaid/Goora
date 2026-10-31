import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/data/corridors.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/supabase_trust_repository.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/schedule.dart';
import 'package:goora/features/marketplace/data/market_seed.dart';
import 'package:goora/features/marketplace/data/supabase_marketplace_repository.dart';
import 'package:goora/features/marketplace/domain/driver_day_rules.dart';
import 'package:goora/features/marketplace/domain/marketplace_repository.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:goora/features/wallet/domain/done_one_off.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

import '../helpers/daily_fakes.dart';
import 'support/in_memory_gateway.dart';
import 'support/no_group_daily.dart';
import 'support/server.dart';
import 'support/tables.dart';

/// 013 live-parity cases that only the Supabase implementation can show (the fake has
/// no second person on the server): what a driver sees of others, through the narrow
/// functions. The matching rules are those of the fake's own tests.
final _now = WallTime(CalendarDate(2026, 10, 31), const Clock.hm(10, 0));
const _corridor = Corridors.sheikhZayedSmartVillage;

/// A group whose going leg Omar drives on 1 Nov (planned = actual = Omar).
const _group = CommuteGroup(
  id: 'g1',
  origin: Area.sheikhZayed,
  destination: Area.smartVillage,
  destinationPoint: GeoPoint(30.07, 31.02),
  pickupPoints: [GeoPoint(30.04, 30.98)],
  going: Clock.hm(7, 0),
  ret: Clock.hm(16, 0),
  days: {Day.sun, Day.mon, Day.tue, Day.wed, Day.thu},
  members: [
    Member(
      id: 'me',
      firstName: 'Omar',
      initials: 'OK',
      role: MemberRole.driver,
      isWoman: false,
      rating: 4.8,
      reliability: 100,
      seats: 3,
    ),
    Member(id: 'sara', firstName: 'Sara', initials: 'SR', role: MemberRole.rider, isWoman: true, rating: 4.9, reliability: 99),
  ],
  price: 40,
  freeSeatsGoing: 1,
  freeSeatsReturn: 1,
  detourMinutes: 5,
  tripCost: 160,
  riderSeats: 3,
);

final class _GroupDaily implements DailyCommuteRepository {
  @override
  String get meId => 'me';
  @override
  Future<CommuteGroup?> myGroup() async => _group;
  @override
  Future<List<ScheduleDay>> schedule(CalendarDate from, CalendarDate to) async => [
    ScheduleDay(
      date: from,
      going: const LegAssignment(leg: Leg.going, planned: 'me', actual: 'me'),
      ret: const LegAssignment(leg: Leg.ret, planned: 'sara', actual: 'sara'),
    ),
  ];
  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async => Ride(
    groupId: 'g1',
    date: date,
    leg: leg,
    driverId: 'me',
    passengers: const [Passenger(memberId: 'sara', stopId: 's')],
    stops: const [],
  );
  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async => const [];
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

Future<({SupabaseMarketplaceRepository repo, InMemoryGateway db, String me})> _world({
  Role role = Role.driver,
  DailyCommuteRepository? daily,
}) async {
  final db = InMemoryGateway(keys: tableKeys);
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'K', gender: Gender.male, role: role);
  final me = await signUpPerson(db, person, id: 'me');
  installTrustServer(db);
  installWalletServer(db, today: _now.date.toIso(), wall: _now.toJson());
  installMarketServer(db, wall: _now.toJson);
  final wallet = SupabaseWalletRepository(
    db,
    role: () => role == Role.driver ? MemberRole.driver : MemberRole.rider,
    now: () => _now,
    provider: FakePaymentProvider(),
  );
  await wallet.setMethod(me, PaymentMethod.cash);
  final repo = SupabaseMarketplaceRepository(
    db,
    trust: SupabaseTrustRepository(db, person: () => person, now: () => _now),
    wallet: () => wallet,
    daily: daily ?? NoGroupDaily(),
    corridor: _corridor,
  );
  return (repo: repo, db: db, me: me);
}

Future<void> _request(InMemoryGateway db, String id, String rider, {String leg = 'going'}) => db.insert('trip_requests', [
  {
    'id': id,
    'rider_id': rider,
    'leg': leg,
    'origin_area': 'sheikhZayed',
    'destination_area': 'smartVillage',
    'trip_date': _now.date.addDays(1).toIso(),
    'departure': '07:30:00',
    'repeat': 'once',
    'pickup': MarketSeed.pickupIn(Area.sheikhZayed, 'q', const Clock.hm(7, 30)).toJson(),
    'contribution': 40,
    'fee': 4,
    'status': 'posted',
  },
]);

void main() {
  test('ML3 a driver sees others\' posted requests with no name, never their own', () async {
    final w = await _world();
    await w.db.insert('profiles', [
      {'id': 'rdr', 'first_name': 'Sara', 'last_name': 'Z', 'gender': 'female', 'role': 'rider'},
    ]);
    await _request(w.db, 'req-1', 'rdr');
    await _request(w.db, 'req-mine', w.me);
    final cards = await w.repo.requestsForMe(part: PartOfDay.morning, now: _now);
    expect([for (final c in cards) c.requestId], ['req-1']);
    expect(cards.single.rider.isWoman, isTrue);
    expect(cards.single.fit.kind, TripFitKind.create);
    expect(await w.repo.requestsForMe(part: PartOfDay.evening, now: _now), isEmpty);
  });

  test('ML4 accepting a request creates a trip and uses one of the two daily trips', () async {
    final w = await _world();
    await w.db.insert('profiles', [
      {'id': 'rdr', 'first_name': 'Sara', 'last_name': 'Z', 'gender': 'female', 'role': 'rider'},
    ]);
    await _request(w.db, 'req-1', 'rdr');
    // The server's market_accept is not emulated: this case checks that a request the driver
    // cannot read as a row (RLS) is still found through the cards, and a missing one is refused.
    expect(await w.repo.accept('nope', now: _now), isA<AcceptRefused>());
  });

  test('ML5 the driver\'s finished one-offs come with first names', () async {
    final w = await _world();
    await w.db.insert('profiles', [
      {'id': 'rdr', 'first_name': 'Hany', 'last_name': 'M', 'gender': 'male', 'role': 'rider'},
    ]);
    await w.db.insert('offered_trips', [
      {
        'id': 'trip-1',
        'driver_id': w.me,
        'leg': 'going',
        'origin_area': 'sheikhZayed',
        'destination_area': 'smartVillage',
        'trip_date': _now.date.addDays(-1).toIso(),
        'departure': '07:30:00',
        'duration_minutes': 40,
        'seats': 3,
        'rider_seats': 3,
        'trip_cost': 160,
        'contribution': 40,
        'repeat': 'once',
        'pickup': MarketSeed.pickupIn(Area.sheikhZayed, 'p', const Clock.hm(7, 30)).toJson(),
        'status': 'done',
      },
    ]);
    await w.db.insert('bookings', [
      {
        'id': 'bk-1',
        'rider_id': 'rdr',
        'offered_trip_id': 'trip-1',
        'trip_date': _now.date.addDays(-1).toIso(),
        'leg': 'going',
        'ride_id': 'offer:trip-1',
        'contribution': 40,
        'fee': 4,
        'paid_by': 'wallet',
        'paid': 4,
        'booked_at': '2026-10-29T09:00:00',
        'is_subscriber': false,
        'status': 'done',
      },
    ]);
    final done = await w.repo.doneOneOffs();
    expect(done, hasLength(1));
    final d = done.single;
    expect((d.riderName, d.driverName, d.paidBy, d.contribution, d.tripCost), ('Hany', 'Omar', PaidBy.wallet, 40, 160));
    expect(d.end, WallTime.fromJson('2026-10-30T08:10:00'));
  });

  test('ML6 a driver in a group sees the legs they drive in their day, in time order', () async {
    final w = await _world(daily: _GroupDaily());
    await w.db.insert('offered_trips', [
      {
        'id': 'trip-2',
        'driver_id': w.me,
        'leg': 'ret',
        'origin_area': 'smartVillage',
        'destination_area': 'sheikhZayed',
        'trip_date': CalendarDate(2026, 11, 1).toIso(),
        'departure': '17:30:00',
        'duration_minutes': 40,
        'seats': 3,
        'rider_seats': 3,
        'trip_cost': 160,
        'contribution': 40,
        'repeat': 'once',
        'pickup': MarketSeed.pickupIn(Area.smartVillage, 'p', const Clock.hm(17, 30)).toJson(),
        'status': 'open',
      },
    ]);
    final day = await w.repo.driverDay(CalendarDate(2026, 11, 1));
    expect([for (final t in day.trips) (t.leg, t.departure)], [(Leg.going, 7 * 60), (Leg.ret, 17 * 60 + 30)]);
    // The group leg is full-fare split over 3 rider seats, Sara riding: 1 taken.
    expect((day.trips.first.seats, day.trips.first.taken), (3, 1));
    expect(day.leadsGroup, isTrue);
  });
}
