enum ChargeReason { lateCancel, noShow }

/// Money a person owes the driver of a ride (FR-012). Collected in 004; no
/// Goora fee is ever added.
final class Charge {
  const Charge({
    required this.id,
    required this.personId,
    required this.rideId,
    required this.reason,
    required this.amount,
    required this.owedTo,
  });

  final String id;
  final String personId;
  final String rideId;
  final ChargeReason reason;

  /// Whole EGP.
  final int amount;

  /// The driver's member id.
  final String owedTo;

  Map<String, Object?> toJson() => {
        'id': id,
        'personId': personId,
        'rideId': rideId,
        'reason': reason.name,
        'amount': amount,
        'owedTo': owedTo,
      };

  static Charge fromJson(Map<String, Object?> j) => Charge(
        id: j['id']! as String,
        personId: j['personId']! as String,
        rideId: j['rideId']! as String,
        reason: ChargeReason.values.byName(j['reason']! as String),
        amount: j['amount']! as int,
        owedTo: j['owedTo']! as String,
      );
}
