import '../../../core/time/calendar_date.dart';

/// Rider trips (`trip`, `cashTrip`) and 003's charges (`lateCancelCharge`,
/// `tripDeduction` for a no-show, `freeCancelZero`) are derived from 003's
/// records at read time (research R3, R7); `topUp`, `withdrawal`,
/// `subscription`, `feeReceived`, `tripIncome` and `cashReceived` are written
/// by this feature's repository.
enum ActivityKind {
  topUp,
  tripDeduction,
  lateCancelCharge,
  freeCancelZero,
  tripIncome,
  feeReceived,
  withdrawal,
  trip,
  cashTrip,
  subscription,
  cashReceived,
}

final class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.fee = 0,
    this.notCollected = false,
    this.rideId,
    this.otherPersonId,
  });

  final String id;
  final ActivityKind kind;

  /// EGP that moved in this wallet; may be 0 (`freeCancelZero`, `cashTrip`, a
  /// charge not collected during the cash trial).
  final int amount;
  final CalendarDate date;

  /// The service-fee part of [amount] (`trip` only).
  final int fee;

  /// A charge skipped because the rider was in the cash trial (amount 0).
  final bool notCollected;

  /// Set for trip-linked kinds; null for `topUp`/`withdrawal`/`subscription`.
  final String? rideId;

  /// Set for `feeReceived`/`cashReceived`: which rider it came from.
  final String? otherPersonId;

  /// What went to the driver: the contribution inside a trip's [amount].
  int get toDriver => amount - fee;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'date': date.toIso(),
        'fee': fee,
        'notCollected': notCollected,
        'rideId': rideId,
        'otherPersonId': otherPersonId,
      };

  static ActivityEntry fromJson(Map<String, Object?> j) => ActivityEntry(
        id: j['id']! as String,
        kind: ActivityKind.values.byName(j['kind']! as String),
        amount: j['amount']! as int,
        date: CalendarDate.parse(j['date']! as String),
        fee: (j['fee'] as int?) ?? 0,
        notCollected: (j['notCollected'] as bool?) ?? false,
        rideId: j['rideId'] as String?,
        otherPersonId: j['otherPersonId'] as String?,
      );
}
