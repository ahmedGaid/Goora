import '../../../core/time/calendar_date.dart';

/// `tripDeduction`/`lateCancelCharge`/`freeCancelZero` are read from 003's
/// `Charge`/`Ride` records at render time (research R3); `topUp`,
/// `withdrawal` and `feeReceived` are the only kinds this feature's own
/// repository creates.
enum ActivityKind { topUp, tripDeduction, lateCancelCharge, freeCancelZero, tripIncome, feeReceived, withdrawal }

final class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.rideId,
    this.otherPersonId,
  });

  final String id;
  final ActivityKind kind;

  /// EGP; may be 0 (`freeCancelZero`).
  final int amount;
  final CalendarDate date;

  /// Set for trip-linked kinds; null for `topUp`/`withdrawal`.
  final String? rideId;

  /// Set for `feeReceived`: which rider's charge reached the driver.
  final String? otherPersonId;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'date': date.toIso(),
        'rideId': rideId,
        'otherPersonId': otherPersonId,
      };

  static ActivityEntry fromJson(Map<String, Object?> j) => ActivityEntry(
        id: j['id']! as String,
        kind: ActivityKind.values.byName(j['kind']! as String),
        amount: j['amount']! as int,
        date: CalendarDate.parse(j['date']! as String),
        rideId: j['rideId'] as String?,
        otherPersonId: j['otherPersonId'] as String?,
      );
}
