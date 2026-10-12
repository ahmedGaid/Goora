import '../../../core/time/calendar_date.dart';
import '../domain/activity_entry.dart';
import '../domain/cash_mark.dart';
import '../domain/payment_method.dart';

/// Seeded wallet data (research R3, R11) so the driver's side has rows and a
/// cash rider to show without replaying 003's flows live.
abstract final class WalletSeed {
  /// Other riders' payment methods. Youssef (group sz-0725) is in the cash
  /// trial, so a driver on that group sees "Received cash" / "Didn't pay".
  static const methods = <String, PaymentMethod>{
    'youssef': PaymentMethod.cash,
    'sara': PaymentMethod.wallet,
  };

  static List<ActivityEntry> driverActivity(CalendarDate today) => [
        ActivityEntry(
          id: 'w-income-1',
          kind: ActivityKind.tripIncome,
          amount: 160,
          date: today.addDays(-1),
          rideId: 'seed-ride-1',
        ),
        ActivityEntry(
          id: 'w-fee-1',
          kind: ActivityKind.feeReceived,
          amount: 20,
          date: today.addDays(-1),
          otherPersonId: 'sara',
        ),
      ];

  /// Cash Youssef handed over on yesterday's seeded ride.
  static CashMark driverCashMark(String driverId, CalendarDate today) => CashMark(
        rideId: 'seed-ride-1',
        riderId: 'youssef',
        driverId: driverId,
        outcome: CashOutcome.received,
        amount: 40,
        date: today.addDays(-1),
      );
}
