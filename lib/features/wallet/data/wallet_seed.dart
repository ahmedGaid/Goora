import '../../../core/time/calendar_date.dart';
import '../domain/activity_entry.dart';

/// Seeded wallet activity (research R3 / T012) so US2/US3's independent
/// tests have rows to show without replaying 003's flows live. Only the
/// kinds this feature's own repository actually writes — tripDeduction,
/// lateCancelCharge and freeCancelZero are read from 003 at render time.
abstract final class WalletSeed {
  static List<ActivityEntry> riderActivity(CalendarDate today) => [
        ActivityEntry(id: 'w-topup-1', kind: ActivityKind.topUp, amount: 400, date: today.addDays(-3)),
      ];

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
}
