import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/cairo_ismailia_seed.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/group.dart';
import 'package:goora/features/commute/domain/place.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';

/// 004 v2.1 research R16 — every seeded group must still fit riderSeats
/// (so a car can't be seeded over its own seat count) and its fixed price
/// must stay inside the range that trip cost/riderSeats allows.
void main() {
  for (final g in CorridorSeed.groups) {
    for (final leg in Leg.values) {
      test('${g.id} ${leg.name}: riders + free seats <= riderSeats, price in range', () {
        final ridersOnLeg = g.riders.where((r) => r.legs.contains(leg)).length;
        expect(ridersOnLeg + g.freeSeats(leg), lessThanOrEqualTo(g.riderSeats),
            reason: '${g.id} ${leg.name}: $ridersOnLeg riders + ${g.freeSeats(leg)} free > ${g.riderSeats} seats');
        expect(PricingService.range(g.tripCost, g.riderSeats).contains(g.price), isTrue,
            reason: '${g.id}: price ${g.price} not in range for tripCost=${g.tripCost} riderSeats=${g.riderSeats}');
      });
    }
  }

  // 006 Cairo <-> Ismailia corridor groups (spec FR, research R6/R8, tasks T026).
  group('006 corridor groups', () {
    final corridor = CairoIsmailiaSeed.groups;
    final toIsmailia = corridor.where((g) => g.destination == Area.ismailia).toList();
    final fromIsmailia = corridor.where((g) => g.origin == Area.ismailia).toList();
    const corridorAreas = {Area.newCairo, Area.nasrCity, Area.heliopolis, Area.obour, Area.tenthOfRamadan, Area.ismailia};

    test('at least 3 groups per direction', () {
      expect(toIsmailia.length, greaterThanOrEqualTo(3));
      expect(fromIsmailia.length, greaterThanOrEqualTo(3));
      expect(toIsmailia.length + fromIsmailia.length, corridor.length);
    });

    test('ids are unique and clear of the old corridor ids', () {
      final ids = [for (final g in corridor) g.id];
      expect(ids.toSet().length, ids.length);
      expect(ids.toSet().intersection({for (final g in CorridorSeed.groups) g.id}), isEmpty);
    });

    for (final dir in {'to Ismailia': toIsmailia, 'from Ismailia': fromIsmailia}.entries) {
      test('${dir.key}: one women-only group, one full group (waitlist demo)', () {
        expect(dir.value.where((g) => g.womenOnly), isNotEmpty);
        expect(dir.value.where((g) => g.freeSeatsGoing == 0 && g.freeSeatsReturn == 0), isNotEmpty);
      });
    }

    test('a women-only group has only women, and a driver', () {
      for (final g in corridor.where((g) => g.womenOnly)) {
        expect(g.members.every((m) => m.isWoman), isTrue, reason: g.id);
        expect(g.drivers, isNotEmpty, reason: g.id);
      }
    });

    for (final g in corridor) {
      test('${g.id}: areas, basis, times, days', () {
        expect(corridorAreas, containsAll([g.origin, g.destination]));
        expect(g.origin, isNot(g.destination));
        expect(g.origin == Area.ismailia || g.destination == Area.ismailia, isTrue);
        expect(g.tripCost, 300);
        expect(g.riderSeats, 3);
        expect(g.price, 76);
        expect(g.days, {Day.sun, Day.mon, Day.tue, Day.wed, Day.thu});
        expect(g.going.minutes, inInclusiveRange(const Clock.hm(6, 30).minutes, const Clock.hm(7, 30).minutes));
        expect(g.ret.minutes, inInclusiveRange(const Clock.hm(16, 30).minutes, const Clock.hm(17, 30).minutes));
        expect(g.freeSeatsGoing, inInclusiveRange(0, 2));
        expect(g.freeSeatsReturn, inInclusiveRange(0, 2));
        expect(g.drivers, isNotEmpty);
        expect(g.stops, isNotEmpty);
      });
      test('${g.id}: arrival is set and matches the corridor trip length', () {
        expect(g.arrival, isNotNull);
        expect(g.tripMinutes, CairoIsmailiaSeed.tripMinutes(g.origin, g.destination));
        expect(g.tripMinutes, isNot(CommuteGroup.defaultTripMinutes));
      });
      for (final leg in Leg.values) {
        test('${g.id} ${leg.name}: riders + free <= 3, price 62-90', () {
          final ridersOnLeg = g.riders.where((r) => r.legs.contains(leg)).length;
          expect(ridersOnLeg + g.freeSeats(leg), lessThanOrEqualTo(3));
          expect(PricingService.range(g.tripCost, g.riderSeats).contains(g.price), isTrue);
          expect(g.price, inInclusiveRange(62, 90));
        });
      }
    }
  });
}
