import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/data/fake_commute_repository.dart';
import 'package:goora/features/commute/data/group_catalog.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/data/fake_daily_commute_repository.dart';
import 'package:goora/features/daily/domain/notice.dart';
import 'package:goora/features/daily/domain/ride.dart';
import 'package:goora/features/daily/domain/rotation_planner.dart';
import 'package:goora/features/onboarding/domain/choices.dart';
import 'package:goora/features/onboarding/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/daily_fakes.dart';

// 005 T029 — research R10 risk, before any UI: a group the marketplace
// created runs one leg only. Nothing may plan the other leg: no assignment,
// no "no driver" day, no no-cover notice.

/// One period of the rotation: Sun 4 Oct – Sat 31 Oct 2026.
const _start = CorridorSeed.rotationStart;
final _end = _start.addDays(RotationPlanner.periodDays - 1);

/// The evening before the period: nothing has settled yet.
final _before = at(_start.addDays(-1), 20, 0);

Member _stored(String id, MemberRole role, Leg leg) => Member(
      id: id,
      firstName: id,
      initials: id.substring(0, 2).toUpperCase(),
      role: role,
      isWoman: false,
      rating: 4.8,
      reliability: 96,
      legs: {leg},
      seats: role == MemberRole.driver ? 3 : null,
    );

/// A daily offer that became a group (R10): every stored member on [leg] only.
CommuteGroup _oneLeg(Leg leg) => CommuteGroup(
      id: 'mk-of-${leg.name}',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: const GeoPoint(30.0719, 31.017),
      pickupPoints: const [GeoPoint(30.0432, 30.981)],
      going: CommuteProfile.defaultDeparture,
      ret: CommuteProfile.defaultReturn,
      days: CommuteProfile.defaultDays,
      members: [_stored('tarek', MemberRole.driver, leg), _stored('nadia', MemberRole.rider, leg)],
      price: 40,
      freeSeatsGoing: leg == Leg.going ? 1 : 0,
      freeSeatsReturn: leg == Leg.ret ? 1 : 0,
      tripCost: 160,
      riderSeats: 3,
      detourMinutes: 0,
      rotationStart: _start,
    );

/// The person joined to [g] as [role], [g] stored the way the marketplace
/// stores a group it created. Their commute profile fits both of the group's
/// times unless [commute] says otherwise; a driver drives both legs
/// (memberPrefs).
Future<(FakeDailyCommuteRepository, TestClock)> _join(CommuteGroup g, Role role, {CommuteProfile? commute}) async {
  SharedPreferences.setMockInitialValues({
    ...memberPrefs(role: role, commute: commute, groupId: g.id),
    if (g.id.startsWith(GroupCatalog.createdPrefix)) ...createdGroupsPrefs([g]),
  });
  final prefs = await SharedPreferences.getInstance();
  final clock = TestClock(_before);
  final person = Profile(phone: testPhone, firstName: 'Omar', lastName: 'Khaled', gender: Gender.male, role: role);
  final repo = FakeDailyCommuteRepository(
    prefs,
    commute: FakeCommuteRepository(prefs),
    person: () => person,
    now: clock.call,
  );
  return (repo, clock);
}

Future<Set<Leg>> _myLegs(FakeDailyCommuteRepository repo) async => (await repo.myGroup())!.member(repo.meId)!.legs;

void main() {
  for (final leg in Leg.values) {
    final other = leg == Leg.going ? Leg.ret : Leg.going;

    group('${leg.name}-only group (005 T029)', () {
      test('RotationPlanner plans ${leg.name} every ride day and never ${other.name}', () {
        final days = RotationPlanner.plan(_oneLeg(leg), _start, _end);
        expect(days, hasLength(20)); // Sun–Thu × 4 weeks
        for (final d in days) {
          expect(d.assignment(other), isNull, reason: '${d.date}');
          expect(d.assignment(leg)?.planned, 'tarek', reason: '${d.date}');
        }
      });

      test('a rider rides ${leg.name} only: no ${other.name} ride, nothing settled on it, no no-cover notice', () async {
        final (repo, clock) = await _join(_oneLeg(leg), Role.rider);
        expect(await _myLegs(repo), {leg});

        for (var date = _start; !date.isAfter(_end); date = date.addDays(1)) {
          clock.now = at(date, 23, 0); // the day's trips settle on this read
          final day = (await repo.schedule(date, date)).singleOrNull;
          if (day == null) continue;
          expect(day.assignment(other), isNull, reason: '$date');
          expect(day.assignment(leg)!.covered, isTrue, reason: '$date');
          expect(await repo.ride(date, other), isNull, reason: '$date');
          expect((await repo.ride(date, leg))!.carries(repo.meId), isTrue, reason: '$date');
        }

        expect((await repo.notices().first).where((n) => n.kind == NoticeKind.noCover), isEmpty);
        final settled = await repo.events(_start, _end);
        expect(settled, hasLength(20));
        expect(settled.map((e) => Ride.parseId(e.rideId)!.$2).toSet(), {leg});
      });

      test('a driver of both legs drives ${leg.name} only, in turn; ${other.name} is never planned', () async {
        final (repo, _) = await _join(_oneLeg(leg), Role.driver);
        expect(await _myLegs(repo), {leg});

        final days = await repo.schedule(_start, _end);
        expect(days, hasLength(20));
        final turns = <String, int>{};
        for (final d in days) {
          expect(d.assignment(other), isNull, reason: '${d.date}');
          expect(await repo.ride(d.date, other), isNull, reason: '${d.date}');
          final driver = d.assignment(leg)!.actual!;
          turns[driver] = (turns[driver] ?? 0) + 1;
        }
        expect(turns, {'tarek': 10, repo.meId: 10});
        expect((await repo.notices().first).where((n) => n.kind == NoticeKind.noCover), isEmpty);
      });
    });
  }

  test('a rider whose times fit only the leg the group does not run still rides its leg', () async {
    // Departure fits, return (9 PM) doesn't: 002's time fit says "going", the
    // group runs "return" only.
    final (repo, _) = await _join(_oneLeg(Leg.ret), Role.rider, commute: corridorProfile(ret: const Clock.hm(21, 0)));
    expect(await _myLegs(repo), {Leg.ret});
  });

  test('a seeded two-leg group is unchanged: a driver joining sz-0725 drives both legs', () async {
    final (repo, _) = await _join(CorridorSeed.groups.first, Role.driver);
    expect(await _myLegs(repo), {Leg.going, Leg.ret});
    final days = await repo.schedule(_start, _end);
    expect(days.every((d) => d.going != null && d.ret != null), isTrue);
  });
}
