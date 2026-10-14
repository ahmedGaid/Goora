import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/geo.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/daily/domain/privacy.dart';

import '../helpers/group_expect.dart';

/// Through a real JSON string, as `market.groups` stores it.
CommuteGroup _roundTrip(CommuteGroup g) =>
    CommuteGroup.fromJson((jsonDecode(jsonEncode(g.toJson())) as Map).cast<String, Object?>());

void main() {
  group('CommuteGroup JSON (005 T027)', () {
    for (final g in CorridorSeed.groups) {
      test('seeded ${g.id} round-trips field by field', () => expectSameGroup(_roundTrip(g), g));
    }

    test('optional fields the seed leaves empty round-trip too', () {
      const g = CommuteGroup(
        id: 'mk-of-test',
        origin: Area.october,
        destination: Area.smartVillage,
        destinationPoint: GeoPoint(30.0719, 31.017),
        pickupPoints: [GeoPoint(29.97, 30.94)],
        going: Clock.hm(7, 30),
        ret: Clock.hm(17, 0),
        days: {Day.sun, Day.tue, Day.thu},
        members: [
          Member(
            id: 'nadia',
            firstName: 'Nadia',
            initials: 'ND',
            role: MemberRole.rider,
            isWoman: true,
            rating: 4.5,
            reliability: 88.5,
            company: 'Valeo',
            compound: 'Beverly Hills',
            legs: {Leg.ret},
            privacy: PrivacyPreference.womenOnly,
            days: {Day.tue},
          ),
        ],
        price: 45,
        freeSeatsGoing: 0,
        freeSeatsReturn: 2,
        tripCost: 160,
        riderSeats: 3,
        detourMinutes: 0,
        womenOnly: true,
        sameCompanyOnly: 'Valeo',
        sameCompoundOnly: 'Beverly Hills',
      );
      final back = _roundTrip(g);
      expectSameGroup(back, g);
      expect(back.stops, isEmpty);
      expect(back.arrival, isNull);
      expect(back.rotationStart, isNull);
    });

    test('a rotation start and member days survive as dates and day sets', () {
      final g = CorridorSeed.groups.first;
      final json = g.toJson();
      expect(json['rotationStart'], '2026-10-04');
      expect(json['days'], ['sun', 'mon', 'tue', 'wed', 'thu']);
      expect(_roundTrip(g).rotationStart, CalendarDate(2026, 10, 4));
    });
  });

  group('CommuteGroup.legs', () {
    test('a seeded group runs both legs', () {
      for (final g in CorridorSeed.groups) {
        expect(g.legs, {Leg.going, Leg.ret}, reason: g.id);
      }
    });

    test('a group whose members all ride one leg runs that leg only', () {
      final g = CorridorSeed.groups.first.withMembers([
        for (final m in CorridorSeed.groups.first.members)
          Member.fromJson({...m.toJson(), 'legs': ['going']}),
      ]);
      expect(g.legs, {Leg.going});
    });
  });
}
