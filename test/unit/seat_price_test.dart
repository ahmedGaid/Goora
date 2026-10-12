import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';

/// 005 research R2 + contracts/pricing.md: one quote for every seat.
void main() {
  SeatPrice at(int contribution, PricingMode mode, {int tripCost = 160, int riderSeats = 3}) =>
      SeatPrice.of(contribution, tripCost: tripCost, riderSeats: riderSeats, mode: mode);

  test('wallet 40 at 160/3 → 40 + 4 fee = 44', () {
    final p = at(40, PricingMode.wallet);
    expect([p.fee, p.total, p.payable], [4, 44, 44]);
  });

  test('subscribed and company pay the contribution, no fee', () {
    for (final mode in [PricingMode.subscribed, PricingMode.company]) {
      final p = at(40, mode);
      expect([p.fee, p.total, p.payable], [0, 40, 40], reason: '$mode');
    }
  });

  test('cash 40 → 40 cash, no fee', () {
    final p = at(40, PricingMode.cash);
    expect([p.fee, p.cash, p.payable], [0, 40, 40]);
    expect(p.cashOffered, isTrue);
  });

  test('cash rounds to the nearest 5 inside the range 32–48 (FR-029)', () {
    expect(at(44, PricingMode.cash).cash, 45);
    expect(at(44, PricingMode.cash).payable, 45);
    expect(at(48, PricingMode.cash).cash, 45);
    expect(at(32, PricingMode.cash).cash, 35);
  });

  test('wallet 44 → 48', () {
    expect(at(44, PricingMode.wallet).total, 48);
  });

  test('160/4 at 38: fee trimmed to 2 (004 v2.1), cash 35', () {
    final wallet = at(38, PricingMode.wallet, riderSeats: 4);
    expect([wallet.fee, wallet.total], [2, 40]);
    expect(at(38, PricingMode.cash, riderSeats: 4).cash, 35);
  });

  test('range 2–2 offers no cash: payable falls back to the total', () {
    for (final c in [2, 8, 4]) {
      final p = at(c, PricingMode.cash, tripCost: 8, riderSeats: 4);
      expect(p.cash, isNull, reason: 'contribution $c');
      expect(p.cashOffered, isFalse);
      expect(p.payable, p.total);
    }
  });
}
