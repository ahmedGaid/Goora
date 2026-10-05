import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/commute_profile.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';

void main() {
  const demo = TripCostConfig();

  test('demo corridor trip cost is 160 while rates are off (founder decision)', () {
    expect(PricingService.tripCost(demo), 160);
    expect(PricingService.tripCost(demo, routeKm: 30), 160);
  });

  test('rates flag on: km × rate + tolls', () {
    const rated = TripCostConfig(ratesEnabled: true, egpPerKm: 4.5, tollsEgp: 10);
    expect(PricingService.tripCost(rated, routeKm: 30), 145);
  });

  test('brief §6.2 demo: 160 EGP, 3 riders → suggested 40, range 32–48', () {
    final r = PricingService.range(160, 3);
    expect(r.suggested, 40);
    expect(r.min, 32);
    expect(r.max, 48);
  });

  test('suggestion rounds to 2 EGP steps; range stays on 2 EGP steps', () {
    for (final riders in [1, 2, 3, 4]) {
      final r = PricingService.range(160, riders);
      expect(r.suggested % 2, 0);
      expect(r.min % 2, 0);
      expect(r.max % 2, 0);
      expect(r.min, lessThanOrEqualTo(r.suggested));
      expect(r.max, greaterThanOrEqualTo(r.suggested));
    }
    expect(PricingService.suggested(160, 1), 80); // 160 / 2
    expect(PricingService.suggested(160, 2), 54); // 53.33 → 54
    expect(PricingService.suggested(160, 4), 32); // 160 / 5
  });

  test('hard cap: riders × max never exceeds the trip cost', () {
    for (final cost in [60, 100, 160, 333]) {
      for (final riders in [1, 2, 3, 4]) {
        final r = PricingService.range(cost, riders);
        expect(riders * r.max, lessThanOrEqualTo(cost), reason: 'cost $cost riders $riders');
      }
    }
    // 1 rider: suggestion 80 ±20 % would allow 96; still ≤ 160.
    expect(PricingService.range(160, 1).max, 96);
  });

  test('snap moves an out-of-range price to the nearest bound', () {
    final r = PricingService.range(160, 3);
    expect(PricingService.snap(60, r), 48);
    expect(PricingService.snap(20, r), 32);
    expect(PricingService.snap(44, r), 44);
  });

  test('recovery per day = seats × price × trips', () {
    expect(PricingService.recoveryPerDay(3, 40, DrivenTrips.both), 240);
    expect(PricingService.recoveryPerDay(3, 48, DrivenTrips.both), 288);
    expect(PricingService.recoveryPerDay(3, 48, DrivenTrips.going), 144);
    expect(PricingService.recoveryPerDay(1, 40, DrivenTrips.ret), 40);
  });

  test('delta label input', () {
    final r = PricingService.range(160, 3);
    expect(PricingService.deltaFromSuggested(40, r), 0);
    expect(PricingService.deltaFromSuggested(48, r), 8);
    expect(PricingService.deltaFromSuggested(34, r), -6);
  });
}
