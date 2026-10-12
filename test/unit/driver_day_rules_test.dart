import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/marketplace/domain/driver_day_rules.dart';

/// 005 research R4 hand cases with the brief's times, plus SC-003: scripted
/// random sequences never give a driver more than 2 trips or 2 in one leg.
void main() {
  int at(int h, int m) => h * 60 + m;

  DayTrip going(String id, int departure, {int seats = 3, int taken = 1}) => DayTrip(
    id: id,
    leg: Leg.going,
    from: Area.sheikhZayed,
    to: Area.smartVillage,
    departure: departure,
    durationMinutes: 40,
    seats: seats,
    taken: taken,
  );

  DayTrip back(String id, int departure) => DayTrip(
    id: id,
    leg: Leg.ret,
    from: Area.smartVillage,
    to: Area.sheikhZayed,
    departure: departure,
    durationMinutes: 40,
    seats: 3,
    taken: 1,
  );

  Candidate goingAt(int departure, {Area from = Area.sheikhZayed, bool daily = false, bool leadsGroup = false}) =>
      Candidate(
        leg: Leg.going,
        from: from,
        to: Area.smartVillage,
        departure: departure,
        durationMinutes: 40,
        daily: daily,
        leadsGroup: leadsGroup,
      );

  Candidate backAt(int departure) =>
      Candidate(leg: Leg.ret, from: Area.smartVillage, to: Area.sheikhZayed, departure: departure, durationMinutes: 40);

  group('each TripFitKind', () {
    test('join: 7:30 trip with a seat, request at 8:00', () {
      expect(DriverDayRules.fit([going('t1', at(7, 30))], goingAt(at(8, 0))), const TripFit.join('t1'));
    });

    test('full: 7:30 trip 3/3, request at 7:40', () {
      expect(DriverDayRules.fit([going('t1', at(7, 30), taken: 3)], goingAt(at(7, 40))), const TripFit.full('t1'));
    });

    test('limitReached: going + return, request at 9:30', () {
      expect(
        DriverDayRules.fit([going('t1', at(7, 30)), back('t2', at(17, 0))], goingAt(at(9, 30))),
        const TripFit.limitReached(),
      );
    });

    test('doesntFit: going trip exists, request from October', () {
      expect(
        DriverDayRules.fit([going('t1', at(7, 30))], goingAt(at(7, 30), from: Area.october)),
        const TripFit.doesntFit(),
      );
    });

    test('oneGroupOnly: a group leader publishing "Every workday"', () {
      expect(DriverDayRules.fit([], goingAt(at(7, 30), daily: true, leadsGroup: true)), const TripFit.oneGroupOnly());
    });

    test('overlap: going 7:30 for 40 min, return at 8:00', () {
      expect(DriverDayRules.fit([going('t1', at(7, 30))], backAt(at(8, 0))), const TripFit.overlap());
    });

    test('create: empty day leaves 1, second trip leaves 0', () {
      expect(DriverDayRules.fit([], goingAt(at(7, 30))), const TripFit.create(1));
      expect(DriverDayRules.fit([going('t1', at(7, 30))], backAt(at(17, 0))), const TripFit.create(0));
    });

    test('tripsLeft never goes below 0', () {
      expect(DriverDayRules.tripsLeft([]), 2);
      expect(DriverDayRules.tripsLeft([going('a', 0), back('b', 600), going('c', 900)]), 0);
    });
  });

  test('SC-003: 10,000 scripted days never exceed 2 trips or 1 trip per leg', () {
    final rnd = Random(20261012);
    const routes = [
      (Leg.going, Area.sheikhZayed, Area.smartVillage),
      (Leg.going, Area.october, Area.smartVillage),
      (Leg.ret, Area.smartVillage, Area.sheikhZayed),
      (Leg.ret, Area.smartVillage, Area.october),
    ];
    var steps = 0;
    for (var s = 0; s < 10000; s++) {
      final leadsGroup = rnd.nextBool();
      final trips = <DayTrip>[];
      // A group leg the driver already drives, some days.
      if (leadsGroup && rnd.nextBool()) {
        trips.add(
          DayTrip(
            id: 'g:going',
            leg: Leg.going,
            from: Area.sheikhZayed,
            to: Area.smartVillage,
            departure: at(7, 25),
            durationMinutes: 40,
            seats: 3,
            taken: 1 + rnd.nextInt(3),
          ),
        );
      }
      final stepCount = 1 + rnd.nextInt(12);
      for (var i = 0; i < stepCount; i++) {
        final (leg, from, to) = routes[rnd.nextInt(routes.length)];
        final isOffer = rnd.nextBool(); // offer: 0 taken; accept / join: 1 rider
        final c = Candidate(
          leg: leg,
          from: from,
          to: to,
          departure: at(6, 0) + rnd.nextInt(14 * 60 + 1),
          durationMinutes: 20 + rnd.nextInt(41),
          daily: rnd.nextBool(),
          leadsGroup: leadsGroup,
        );
        final f = DriverDayRules.fit(trips, c);
        if (f.kind == TripFitKind.create) {
          trips.add(
            DayTrip(
              id: 's$s-$i',
              leg: c.leg,
              from: c.from,
              to: c.to,
              departure: c.departure,
              durationMinutes: c.durationMinutes,
              seats: 1 + rnd.nextInt(3),
              taken: isOffer ? 0 : 1,
            ),
          );
        } else if (f.kind == TripFitKind.join) {
          final k = trips.indexWhere((t) => t.id == f.tripId);
          trips[k] = trips[k].withTaken(trips[k].taken + 1);
          expect(trips[k].taken, lessThanOrEqualTo(trips[k].seats), reason: 'sequence $s step $i');
        }
        expect(trips.length, lessThanOrEqualTo(DriverDayRules.maxTrips), reason: 'sequence $s step $i');
        for (final leg in Leg.values) {
          expect(trips.where((t) => t.leg == leg).length, lessThanOrEqualTo(1), reason: 'sequence $s step $i $leg');
        }
        steps++;
      }
    }
    expect(steps, greaterThan(10000));
  });
}
