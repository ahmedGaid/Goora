import 'package:flutter_test/flutter_test.dart';
import 'package:goora/core/time/calendar_date.dart';
import 'package:goora/core/time/wall_time.dart';
import 'package:goora/features/commute/domain/clock.dart';
import 'package:goora/features/marketplace/domain/booking_gate.dart';
import 'package:goora/features/wallet/domain/direct_pay.dart';
import 'package:goora/features/wallet/domain/payment_method.dart';
import 'package:goora/features/wallet/domain/share.dart';

/// 005 research R8, 007 FR-005: owesDriver | needsMethod | ok, in that
/// order. Goora's own fee never blocks (007 research R5).
void main() {
  Share share(ShareStatus status, {int amount = 40, String name = 'Karim', int day = 1}) => Share(
        rideId: 'r$day',
        riderId: 'me',
        driverId: 'd',
        otherFirstName: name,
        amount: amount,
        method: PaymentMethod.cash,
        tripEnd: WallTime(CalendarDate(2026, 10, day), const Clock.hm(8, 0)),
        status: status,
      );

  test('no method and no plan → needsMethod', () {
    expect(BookingGate.check(hasArrangement: false, openShares: const []), BookingCheck.needsMethod);
  });

  test('nothing owed → ok', () {
    expect(BookingGate.check(hasArrangement: true, openShares: const []), BookingCheck.ok);
  });

  test('pending and received shares never block', () {
    final shares = [share(ShareStatus.pending), share(ShareStatus.received), share(ShareStatus.autoReceived)];
    expect(BookingGate.check(hasArrangement: true, openShares: shares), BookingCheck.ok);
  });

  test('a "didn\'t get it" share blocks with the amount and the driver', () {
    expect(BookingGate.check(hasArrangement: true, openShares: [share(ShareStatus.notReceived)]),
        const BookingCheck.owesDriver(40, 'Karim'));
  });

  test('a disputed share still blocks', () {
    expect(BookingGate.check(hasArrangement: true, openShares: [share(ShareStatus.disputed)]).kind,
        BookingCheckKind.owesDriver);
  });

  test('several debts: everything owed, the oldest driver named', () {
    final shares = [
      share(ShareStatus.notReceived, day: 5, name: 'Omar', amount: 45),
      share(ShareStatus.disputed, day: 2, name: 'Karim'),
    ];
    expect(BookingGate.check(hasArrangement: true, openShares: shares), const BookingCheck.owesDriver(85, 'Karim'));
  });

  test('a debt blocks before the missing method', () {
    expect(BookingGate.check(hasArrangement: false, openShares: [share(ShareStatus.notReceived)]).kind,
        BookingCheckKind.owesDriver);
  });
}
