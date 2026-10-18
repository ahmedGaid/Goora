import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';

/// 005 research R2 + contracts/pricing.md, 007 research R4: one quote for
/// every seat — the share the rider hands the driver and Goora's own fee.
void main() {
  SeatPrice at(int contribution, PricingMode mode,
          {int tripCost = 160, int riderSeats = 3, PaymentMethod method = PaymentMethod.cash}) =>
      SeatPrice.of(contribution, tripCost: tripCost, riderSeats: riderSeats, mode: mode, method: method);

  test('per trip 40 at 160/3 → 40 to the driver + 4 fee = 44', () {
    final p = at(40, PricingMode.perTrip);
    expect([p.share, p.fee, p.total], [40, 4, 44]);
  });

  test('trial, subscribed and company: the share only, no fee', () {
    for (final mode in [PricingMode.trial, PricingMode.subscribed, PricingMode.company]) {
      final p = at(40, mode);
      expect([p.share, p.fee, p.total], [40, 0, 40], reason: '$mode');
    }
  });

  test('cash rounds the share to the nearest 5 inside the range 32–48 (FR-029)', () {
    expect(at(44, PricingMode.trial).share, 45);
    expect(at(48, PricingMode.trial).share, 45);
    expect(at(32, PricingMode.trial).share, 35);
  });

  test('InstaPay pays the exact contribution', () {
    expect(at(44, PricingMode.trial, method: PaymentMethod.instapay).share, 44);
  });

  test('per trip 44 paid in cash → 45 + 4 = 49 (fee from the contribution, R4)', () {
    final p = at(44, PricingMode.perTrip);
    expect([p.share, p.fee, p.total], [45, 4, 49]);
  });

  test('160/4 at 38: InstaPay fee trimmed to 2; cash 35 leaves room for 4', () {
    final instapay = at(38, PricingMode.perTrip, riderSeats: 4, method: PaymentMethod.instapay);
    expect([instapay.share, instapay.fee, instapay.total], [38, 2, 40]);
    final cash = at(38, PricingMode.perTrip, riderSeats: 4);
    expect([cash.share, cash.fee, cash.total], [35, 4, 39]);
  });

  test('range 2–2 has no cash multiple: the share is the exact contribution', () {
    expect(at(2, PricingMode.trial, tripCost: 8, riderSeats: 4).share, 2);
  });

  test('a 004/005 stored quote reads as trial / per trip', () {
    final cash = SeatPrice.fromJson({'contribution': 44, 'fee': 0, 'cash': 45, 'mode': 'cash'});
    expect([cash.mode, cash.share], [PricingMode.trial, 45]);
    final wallet = SeatPrice.fromJson({'contribution': 40, 'fee': 4, 'cash': null, 'mode': 'wallet'});
    expect([wallet.mode, wallet.share, wallet.fee], [PricingMode.perTrip, 40, 4]);
  });

  test('round-trips through JSON', () {
    final p = at(44, PricingMode.perTrip, method: PaymentMethod.instapay);
    expect(SeatPrice.fromJson(p.toJson()), p);
  });
}
