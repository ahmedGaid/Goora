import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/commute/domain/pricing_service.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';

/// 007 research R4 — Constitution II on direct pay, proved by sweep: for every
/// allowed price and both ways of paying the driver, what the rider hands the
/// driver plus Goora's fee never passes their equal share, so riders' total
/// never exceeds the trip cost — cash rounding up included.
void main() {
  test('share + fee stays within the equal share for every allowed price', () {
    var checked = 0;
    for (var tripCost = 20; tripCost <= 1000; tripCost += 2) {
      for (var riderSeats = 1; riderSeats <= 4; riderSeats++) {
        final range = PricingService.range(tripCost, riderSeats);
        final cap = PricingService.equalShare(tripCost, riderSeats);
        for (var c = range.min; c <= range.max; c += 2) {
          if (c <= 0) continue;
          for (final method in PaymentMethod.values) {
            final share = DirectPay.share(c, method: method, tripCost: tripCost, riderSeats: riderSeats);
            final fee = DirectPay.fee(c, share: share, tripCost: tripCost, riderSeats: riderSeats, feeFree: false);
            final why = 'tripCost=$tripCost seats=$riderSeats c=$c ${method.name} share=$share fee=$fee';
            expect(share, greaterThan(0), reason: why);
            expect(fee, greaterThanOrEqualTo(0), reason: why);
            expect(share + fee, lessThanOrEqualTo(cap), reason: why);
            checked++;
          }
        }
      }
    }
    expect(checked, greaterThan(1000));
  });
}
