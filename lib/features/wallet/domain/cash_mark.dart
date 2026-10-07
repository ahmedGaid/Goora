import '../../../core/time/calendar_date.dart';

enum CashOutcome { received, didNotPay }

/// A driver's record of one cash rider on one ride (brief §6.7 C). One per
/// (ride, rider); the first mark stands.
final class CashMark {
  const CashMark({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.outcome,
    required this.amount,
    required this.date,
  });

  final String rideId;
  final String riderId;
  final String driverId;
  final CashOutcome outcome;

  /// The contribution in whole EGP.
  final int amount;
  final CalendarDate date;

  Map<String, Object?> toJson() => {
        'rideId': rideId,
        'riderId': riderId,
        'driverId': driverId,
        'outcome': outcome.name,
        'amount': amount,
        'date': date.toIso(),
      };

  static CashMark fromJson(Map<String, Object?> j) => CashMark(
        rideId: j['rideId']! as String,
        riderId: j['riderId']! as String,
        driverId: j['driverId']! as String,
        outcome: CashOutcome.values.byName(j['outcome']! as String),
        amount: j['amount']! as int,
        date: CalendarDate.parse(j['date']! as String),
      );
}
