import '../../../core/time/wall_time.dart';
import 'direct_pay.dart';
import 'payment_method.dart';

/// One rider's share for one ride, paid to the driver outside Goora (007
/// data-model "Share"). Derived on read from the ride, the driver's mark and
/// the rider's claim — never stored, never a wallet movement (FR-001).
final class Share {
  const Share({
    required this.rideId,
    required this.riderId,
    required this.driverId,
    required this.otherFirstName,
    required this.amount,
    required this.method,
    required this.tripEnd,
    required this.status,
    this.reversedOnce = false,
  });

  final String rideId;
  final String riderId;
  final String driverId;

  /// The other party's first name only (FR-018): the driver's for the rider,
  /// the rider's for the driver.
  final String otherFirstName;

  /// Whole EGP the rider hands the driver.
  final int amount;
  final PaymentMethod method;
  final WallTime tripEnd;
  final ShareStatus status;

  /// The driver already turned an auto-received share into "didn't pay".
  final bool reversedOnce;
}

/// A rider's "دفعت" on a share the driver marked as not received (FR-006).
final class PaidClaim {
  const PaidClaim({required this.rideId, required this.riderId, required this.claimedAt});

  final String rideId;
  final String riderId;
  final WallTime claimedAt;

  Map<String, Object?> toJson() => {'rideId': rideId, 'riderId': riderId, 'claimedAt': claimedAt.toJson()};

  static PaidClaim fromJson(Map<String, Object?> j) => PaidClaim(
        rideId: j['rideId']! as String,
        riderId: j['riderId']! as String,
        claimedAt: WallTime.fromJson(j['claimedAt']! as String),
      );
}
