import '../../../core/time/wall_time.dart';

/// The driver tapped "I've arrived at …" for one stop.
final class StopCheckIn {
  const StopCheckIn({required this.rideId, required this.stopId, required this.arrivedAt});

  final String rideId;
  final String stopId;
  final WallTime arrivedAt;

  Map<String, Object?> toJson() => {'rideId': rideId, 'stopId': stopId, 'arrivedAt': arrivedAt.toJson()};

  static StopCheckIn fromJson(Map<String, Object?> j) => StopCheckIn(
        rideId: j['rideId']! as String,
        stopId: j['stopId']! as String,
        arrivedAt: WallTime.fromJson(j['arrivedAt']! as String),
      );
}

enum Outcome { waiting, pickedUp, noShow }

/// The driver's latest mark for one passenger; switchable until the trip
/// starts, the last mark counts.
final class PassengerOutcome {
  const PassengerOutcome({
    required this.rideId,
    required this.personId,
    required this.outcome,
    required this.markedAt,
  });

  final String rideId;
  final String personId;
  final Outcome outcome;
  final WallTime markedAt;

  Map<String, Object?> toJson() =>
      {'rideId': rideId, 'personId': personId, 'outcome': outcome.name, 'markedAt': markedAt.toJson()};

  static PassengerOutcome fromJson(Map<String, Object?> j) => PassengerOutcome(
        rideId: j['rideId']! as String,
        personId: j['personId']! as String,
        outcome: Outcome.values.byName(j['outcome']! as String),
        markedAt: WallTime.fromJson(j['markedAt']! as String),
      );
}
