import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';

/// 004 v2.1 research R17 — Constitution II's cap (FR-016, spec SC-006), proved
/// by sweep rather than inspection: for every allowed price, no rider ever pays
/// more than their equal share, so riders' total never exceeds the trip cost.
/// Mirrored in supabase/functions/_shared/pricing.test.ts.
void main() {
  test('every allowed price keeps riders\' total within the trip cost', () {
    var checked = 0;
    for (var tripCost = 20; tripCost <= 1000; tripCost += 20) {
      for (var riderSeats = 1; riderSeats <= 4; riderSeats++) {
        final range = PricingService.range(tripCost, riderSeats);
        for (var c = range.min; c <= range.max; c += 2) {
          final total = PricingService.riderTotal(c,
              tripCost: tripCost, riderSeats: riderSeats, isSubscriber: false, isCashTrial: false);
          expect(riderSeats * total, lessThanOrEqualTo(tripCost),
              reason: 'tripCost=$tripCost riderSeats=$riderSeats contribution=$c total=$total');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(0));
  });
}
