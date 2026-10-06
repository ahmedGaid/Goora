import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/rotation_planner.dart';
import 'package:goora/features/daily/domain/schedule.dart';

final _start = CalendarDate(2026, 10, 4); // Sunday

Member _driver(String id, {Set<Leg> legs = const {Leg.going, Leg.ret}, Set<Day>? days}) => Member(
      id: id,
      firstName: id,
      initials: id,
      role: MemberRole.driver,
      isWoman: false,
      rating: 4.8,
      reliability: 95,
      legs: legs,
      days: days,
    );

CommuteGroup _group(List<Member> drivers) => CommuteGroup(
      id: 'g',
      origin: Area.sheikhZayed,
      destination: Area.smartVillage,
      destinationPoint: const GeoPoint(30.07, 31.01),
      pickupPoints: const [GeoPoint(30.04, 30.98)],
      going: const Clock.hm(7, 25),
      ret: const Clock.hm(17, 0),
      days: CommuteProfile.defaultDays,
      members: drivers,
      price: 40,
      freeSeatsGoing: 1,
      freeSeatsReturn: 1,
      detourMinutes: 5,
      rotationStart: _start,
    );

Map<String, int> _counts(List<ScheduleDay> days, Leg leg) {
  final counts = <String, int>{};
  for (final d in days) {
    final id = d.assignment(leg)?.planned;
    if (id != null) counts[id] = (counts[id] ?? 0) + 1;
  }
  return counts;
}

void _expectFair(Map<String, int> counts, int drivers) {
  expect(counts.length, drivers, reason: 'every driver drives: $counts');
  final values = counts.values;
  expect(values.reduce((a, b) => a > b ? a : b) - values.reduce((a, b) => a < b ? a : b), lessThanOrEqualTo(1),
      reason: '$counts');
}

void main() {
  final periodEnd = _start.addDays(RotationPlanner.periodDays - 1);

  for (final n in [2, 3]) {
    test('$n drivers × 4 weeks → max − min ≤ 1 per leg per period (SC-005)', () {
      final g = _group([for (var i = 0; i < n; i++) _driver('d$i')]);
      for (var period = 0; period < 3; period++) {
        final from = _start.addDays(period * RotationPlanner.periodDays);
        final days = RotationPlanner.plan(g, from, from.addDays(RotationPlanner.periodDays - 1));
        expect(days, hasLength(20), reason: '5 ride days a week');
        for (final leg in Leg.values) {
          _expectFair(_counts(days, leg), n);
        }
      }
    });
  }

  test('going-only and return-only drivers only get their leg', () {
    final g = _group([_driver('a', legs: {Leg.going}), _driver('b', legs: {Leg.ret})]);
    final days = RotationPlanner.plan(g, _start, periodEnd);
    expect(days.every((d) => d.going!.planned == 'a' && d.ret!.planned == 'b'), isTrue);
  });

  test('a leg no driver offers has no assignment', () {
    final g = _group([_driver('a', legs: {Leg.going})]);
    final days = RotationPlanner.plan(g, _start, periodEnd);
    expect(days.every((d) => d.ret == null), isTrue);
  });

  test("a driver's chosen days are respected", () {
    final g = _group([
      _driver('a', days: {Day.sun, Day.mon}),
      _driver('b'),
    ]);
    final days = RotationPlanner.plan(g, _start, periodEnd);
    for (final d in days) {
      if (!{Day.sun, Day.mon}.contains(d.date.weekday)) expect(d.going!.planned, 'b');
    }
    expect(_counts(days, Leg.going)['a'], greaterThan(0));
  });

  test('an unavailable day reassigns without changing period counts', () {
    final g = _group([_driver('a'), _driver('b')]);
    final base = RotationPlanner.plan(g, _start, periodEnd);
    final aDay = base.firstWhere((d) => d.going!.planned == 'a').date;
    final days = RotationPlanner.plan(g, _start, periodEnd, unavailable: {('a', aDay, Leg.going)});
    expect(days.firstWhere((d) => d.date == aDay).going!.planned, 'b');
    expect(_counts(days, Leg.going), _counts(base, Leg.going));
  });

  test('no eligible driver that day → planned null (uncovered)', () {
    final g = _group([_driver('a')]);
    final day = _start.addDays(1);
    final days = RotationPlanner.plan(g, day, day, unavailable: {('a', day, Leg.going)});
    expect(days.single.going!.planned, isNull);
    expect(days.single.going!.covered, isFalse);
  });

  test('deterministic, and the window does not change who drives', () {
    final g = _group([_driver('c'), _driver('a'), _driver('b')]);
    final whole = RotationPlanner.plan(g, _start, periodEnd);
    final again = RotationPlanner.plan(g, _start, periodEnd);
    expect([for (final d in whole) d.going!.planned], [for (final d in again) d.going!.planned]);
    final mid = _start.addDays(10);
    final window = RotationPlanner.plan(g, mid, mid.addDays(6));
    for (final d in window) {
      expect(d.going!.planned, whole.firstWhere((w) => w.date == d.date).going!.planned);
    }
    expect(whole.first.going!.planned, 'a', reason: 'ties → lowest id first');
  });

  test('non-working days are skipped', () {
    final g = _group([_driver('a')]);
    final days = RotationPlanner.plan(g, _start, _start.addDays(6));
    expect([for (final d in days) d.date.weekday], [Day.sun, Day.mon, Day.tue, Day.wed, Day.thu]);
  });
}
