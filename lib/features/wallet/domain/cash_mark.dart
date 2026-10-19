import '../../../core/time/calendar_date.dart';
import '../../../core/time/wall_time.dart';

enum CashOutcome { received, didNotPay }

/// A driver's answer for one rider's share on one ride (004 §6.7 C, widened
/// by 007 research R1 to every paying rider, cash or InstaPay). The latest
/// mark per (ride, rider) stands while `SharePolicy.canMark` allowed it.
final class CashMark {
  const CashMark({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.outcome,
    required this.amount,
    required this.date,
    this.markedAt,
  });

  final String rideId;
  final String riderId;
  final String driverId;
  final CashOutcome outcome;

  /// The share in whole EGP.
  final int amount;
  final CalendarDate date;

  /// When the driver answered; null on 004 rows (read as [date] at 00:00).
  final WallTime? markedAt;

  Map<String, Object?> toJson() => {
        'rideId': rideId,
        'riderId': riderId,
        'driverId': driverId,
        'outcome': outcome.name,
        'amount': amount,
        'date': date.toIso(),
        if (markedAt != null) 'markedAt': markedAt!.toJson(),
      };

  static CashMark fromJson(Map<String, Object?> j) => CashMark(
        rideId: j['rideId']! as String,
        riderId: j['riderId']! as String,
        driverId: j['driverId']! as String,
        outcome: CashOutcome.values.byName(j['outcome']! as String),
        amount: j['amount']! as int,
        date: CalendarDate.parse(j['date']! as String),
        markedAt: j['markedAt'] == null ? null : WallTime.fromJson(j['markedAt']! as String),
      );
}
