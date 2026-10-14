import 'package:flutter_test/flutter_test.dart';
import 'package:goora/features/marketplace/domain/booking_gate.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/seat_price.dart';

/// 005 research R8: ok | needsMethod | topUp(gap), in that order.
void main() {
  BookingCheck check(
    PricingMode mode,
    int contribution,
    int balance, {
    bool hasArrangement = true,
    int tripCost = 160,
    int riderSeats = 3,
  }) {
    final price = SeatPrice.of(contribution, tripCost: tripCost, riderSeats: riderSeats, mode: mode);
    return BookingGate.check(
      hasArrangement: hasArrangement,
      mode: mode,
      cashOffered: price.cashOffered,
      balance: balance,
      price: price,
    );
  }

  test('no method and no plan → needsMethod', () {
    expect(check(PricingMode.wallet, 40, 500, hasArrangement: false), BookingCheck.needsMethod);
  });

  test('company is never blocked, even at −50', () {
    expect(check(PricingMode.company, 40, -50), BookingCheck.ok);
  });

  test('cash with cash offered → ok at any balance', () {
    expect(check(PricingMode.cash, 40, 0), BookingCheck.ok);
  });

  test('cash with no cash amount (range 2–2) at balance 0 → top up the total', () {
    final price = SeatPrice.of(2, tripCost: 8, riderSeats: 4, mode: PricingMode.cash);
    expect(price.cash, isNull);
    expect(check(PricingMode.cash, 2, 0, tripCost: 8, riderSeats: 4), BookingCheck.topUp(price.total));
  });

  test('wallet 44: balance 0 → top up 44, 30 → 14, 44 → ok', () {
    // 40 + 4 fee at 160/3.
    expect(check(PricingMode.wallet, 40, 0), const BookingCheck.topUp(44));
    expect(check(PricingMode.wallet, 40, 30), const BookingCheck.topUp(14));
    expect(check(PricingMode.wallet, 40, 44), BookingCheck.ok);
  });

  test('subscribed 40 at 39 → top up 1', () {
    expect(check(PricingMode.subscribed, 40, 39), const BookingCheck.topUp(1));
  });
}
