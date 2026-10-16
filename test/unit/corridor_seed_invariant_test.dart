import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/data/corridor_seed.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
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


  // 006 Cairo <-> Ismailia corridor-group rules (spec FR, research R6/R8).
  // EXPECTED RED until P5 seeds the corridor groups: before then there are none,
  // so this test fails on purpose rather than passing on an empty list.
  group('006 corridor groups', () {
    final corridor = CorridorSeed.groups.where((g) => g.tripCost == 300).toList();

    test('corridor groups are seeded (red until P5)', () {
      expect(corridor, isNotEmpty, reason: 'P5 (T026) seeds the 300 EGP corridor groups');
    });

    for (final g in corridor) {
      for (final leg in Leg.values) {
        test('${g.id} ${leg.name}: riders + free <= 3, price 62-90', () {
          final ridersOnLeg = g.riders.where((r) => r.legs.contains(leg)).length;
          expect(ridersOnLeg + g.freeSeats(leg), lessThanOrEqualTo(3));
          expect(g.price, inInclusiveRange(62, 90));
        });
      }
      test('${g.id}: arrival is set, not the 40-minute default', () {
        expect(g.arrival, isNotNull);
      });
    }
  });
}
