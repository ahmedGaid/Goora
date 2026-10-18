import '../../../core/time/calendar_date.dart';

/// Rider trips (`trip`, `cashTrip`) and 003's charges (`lateCancelCharge`,
/// `tripDeduction` for a no-show, `freeCancelZero`) are derived from 003's
/// records at read time (research R3, R7); `topUp`, `withdrawal`,
/// `subscription`, `feeReceived`, `tripIncome` and `cashReceived` are written
/// by this feature's repository. `seatBooked` (a one-off seat paid at booking,
/// fee recorded) and `seatRefund` (its one credit back) are written through
/// `SeatLedger` (005 research R7).
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
  seatBooked,
  seatRefund,
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
    this.shareToDriver = 0,
  });

  final String id;
  final ActivityKind kind;

  /// Goora's money that moved in this wallet; may be 0 (`freeCancelZero`, a
  /// fee-free `cashTrip` trial trip, a charge paid to the driver directly).
  final int amount;
  final CalendarDate date;

  /// The service-fee part of [amount] (`trip`, `seatBooked`).
  final int fee;

  /// A charge skipped because the rider was in the cash trial (amount 0).
  final bool notCollected;

  /// Set for trip-linked kinds; null for `topUp`/`withdrawal`/`subscription`.
  final String? rideId;

  /// Set for `feeReceived`/`cashReceived`: which rider it came from.
  final String? otherPersonId;

  /// The share the rider handed the driver directly for this trip (007
  /// FR-001) — shown, never part of [amount] or the balance. 0 on 004/005
  /// rows, where the share was inside [amount].
  final int shareToDriver;

  /// What went to the driver for this trip.
  int get toDriver => shareToDriver > 0 ? shareToDriver : amount - fee;

  Map<String, Object?> toJson() => {
        'id': id,
        'kind': kind.name,
        'amount': amount,
        'date': date.toIso(),
        'fee': fee,
        'notCollected': notCollected,
        'rideId': rideId,
        'otherPersonId': otherPersonId,
        if (shareToDriver != 0) 'shareToDriver': shareToDriver,
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
        shareToDriver: (j['shareToDriver'] as int?) ?? 0,
      );
}
