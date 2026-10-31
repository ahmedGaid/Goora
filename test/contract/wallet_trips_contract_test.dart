import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/absence.dart';
import 'package:goora/features/daily/domain/charge.dart';
import 'package:goora/features/daily/domain/check_in.dart';
import 'package:goora/features/daily/domain/daily_commute_repository.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/trust.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/phone_number.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:goora/features/wallet/data/fake_payment_provider.dart';
import 'package:goora/features/wallet/data/fake_wallet_repository.dart';
import 'package:goora/features/wallet/data/supabase_wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_gateway.dart';
import 'support/server.dart';
import 'support/tables.dart';
import 'wallet_trips_contract.dart';

const _groupId = 'g1';

const _group = CommuteGroup(
  id: _groupId,
  origin: Area.newCairo,
  destination: Area.ismailia,
  destinationPoint: GeoPoint(30.6, 32.27),
  pickupPoints: [GeoPoint(30.03, 31.47)],
  going: Clock.hm(7, 0),
  ret: Clock.hm(16, 0),
  days: CommuteProfile.defaultDays,
  members: [
    Member(id: 'me', firstName: 'Omar', initials: 'OK', role: MemberRole.rider, isWoman: false, rating: 4.8, reliability: 100),
    Member(
      id: 'drv',
      firstName: 'Dina',
      initials: 'DT',
      role: MemberRole.driver,
      isWoman: true,
      rating: 4.9,
      reliability: 99,
      seats: 3,
    ),
  ],
  price: 40,
  freeSeatsGoing: 1,
  freeSeatsReturn: 1,
  detourMinutes: 5,
  tripCost: 160,
  riderSeats: 3,
);

/// What 003 recorded for the rider: finished going legs of group g1, driven by Dina.
final class _TripsDaily implements DailyCommuteRepository {
  final Set<CalendarDate> finished = {};

  @override
  String get meId => 'me';
  @override
  Future<CommuteGroup?> myGroup() async => _group;
  @override
  Future<List<ReliabilityEvent>> events(CalendarDate from, CalendarDate to) async => [
    for (final d in finished)
      if (!d.isBefore(from) && !d.isAfter(to))
        ReliabilityEvent(
          personId: 'me',
          rideId: Ride.idFor(_groupId, d, Leg.going),
          date: d,
          kind: ReliabilityEventKind.kept,
        ),
  ];
  @override
  Future<List<Charge>> chargesOwed() async => const [];
  @override
  Future<List<Absence>> absences(CalendarDate from, CalendarDate to) async => const [];
  @override
  Future<Ride?> ride(CalendarDate date, Leg leg) async => finished.contains(date) && leg == Leg.going
      ? Ride(
          groupId: _groupId,
          date: date,
          leg: leg,
          driverId: 'drv',
          passengers: const [Passenger(memberId: 'me', stopId: 's')],
          stops: const [],
          endedAt: WallTime(date, const Clock.hm(8, 0)),
        )
      : null;
  @override
  Future<List<PassengerOutcome>> outcomes(String rideId) async => const [];
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

WallTime _at(CalendarDate d) => WallTime(d, const Clock.hm(9, 0));

void main() {
  walletTripsContract('fake', () async {
    SharedPreferences.setMockInitialValues({});
    var today = CalendarDate(2026, 10, 1);
    final daily = _TripsDaily();
    final repo = FakeWalletRepository(
      await SharedPreferences.getInstance(),
      daily: daily,
      role: () => MemberRole.rider,
      now: () => _at(today),
      provider: FakePaymentProvider(),
    );
    return (
      wallet: repo,
      ledger: repo,
      me: 'me',
      finishTrips: (Iterable<CalendarDate> days) async => daily.finished.addAll(days),
      setToday: (CalendarDate d) => today = d,
    );
  });

  walletTripsContract('supabase', () async {
    final db = InMemoryGateway(keys: tableKeys);
    final me = await signUpPerson(
      db,
      Profile(phone: PhoneNumber.tryParse('01001234567')!, firstName: 'Omar', lastName: 'K', gender: Gender.male),
    );
    var today = CalendarDate(2026, 10, 1);
    installWalletServer(db, today: today.toIso(), wall: _at(today).toJson(), clock: () => today.toIso());
    await db.insert('profiles', [
      {'id': 'drv', 'first_name': 'Dina', 'last_name': 'T', 'gender': 'female', 'role': 'driver'},
    ]);
    await db.insert('groups', [
      {
        'id': _groupId,
        'price': 40,
        'going': '07:00',
        'return_time': '16:00',
        'arrival': null,
        'card': {'tripCost': 160, 'riderSeats': 3},
      },
    ]);
    final repo = SupabaseWalletRepository(
      db,
      role: () => MemberRole.rider,
      now: () => _at(today),
      provider: FakePaymentProvider(),
    );
    return (
      wallet: repo,
      ledger: repo,
      me: me,
      finishTrips: (Iterable<CalendarDate> days) async {
        for (final d in days) {
          final rideId = Ride.idFor(_groupId, d, Leg.going);
          await db.insert('rides', [
            {
              'id': rideId,
              'group_id': _groupId,
              'ride_date': d.toIso(),
              'leg': 'going',
              'driver_id': 'drv',
              'ended_at': '${d.toIso()}T08:00:00',
            },
          ]);
          await db.insert('reliability_events', [
            {'user_id': me, 'ride_id': rideId, 'ride_date': d.toIso(), 'kind': 'kept'},
          ]);
        }
      },
      setToday: (CalendarDate d) => today = d,
    );
  });
}
