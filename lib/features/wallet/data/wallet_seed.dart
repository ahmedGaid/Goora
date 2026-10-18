import '../../../core/time/calendar_date.dart';
import '../domain/cash_mark.dart';
import '../domain/payment_method.dart';

/// Seeded wallet data (research R3, R11) so the driver's side has a
/// confirmed share to show without replaying 003's flows live.
abstract final class WalletSeed {
  /// How other riders pay the driver (007 FR-013).
  static const methods = <String, PaymentMethod>{
    'youssef': PaymentMethod.cash,
    'sara': PaymentMethod.instapay,
  };

  /// Seeded drivers' InstaPay handles, so a rider sees one to copy.
  static const instapayHandles = <String, String>{'ahmed': 'ahmed.k@instapay'};

  /// First names for seeded marks whose ride isn't in 003's records.
  static const riderNames = <String, String>{'youssef': 'Youssef', 'sara': 'Sara'};

  /// The share Youssef handed over in cash on yesterday's seeded ride.
  static CashMark driverCashMark(String driverId, CalendarDate today) => CashMark(
        rideId: 'seed-ride-1',
        riderId: 'youssef',
        driverId: driverId,
        outcome: CashOutcome.received,
        amount: 40,
        date: today.addDays(-1),
      );
}
